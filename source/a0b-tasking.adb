--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with System.Machine_Code;
with System.Storage_Elements;         use System.Storage_Elements;

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.ARMv7M.System_Timer;         use A0B.ARMv7M.System_Timer;
with A0B.Types.GCC_Builtins;

with A0B.Tasking.Context_Switching;
with A0B.Tasking.Interrupt_Handling;
with A0B.Tasking.Scheduler;
with A0B.Tasking.System_Timer;

package body A0B.Tasking is

   Next_Stack : System.Address;

   --  function To_Priority_Value
   --    (Item : Priority) return A0B.ARMv7M.Priority_Value is
   --      (A0B.ARMv7M.Priority_Value
   --        (Priority (A0B.ARMv7M.Priority_Value'Last) - Item));
   --  Conversion from abstract priority level to ARM priority value.

   estack : constant A0B.Types.Reserved_32
     with Import, Convention => C, External_Name => "_estack";

   procedure Idle_Thread;
   --  Thread that run idle loop.

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (Time_Stamp : A0B.Types.Unsigned_64) is
   begin
      Scheduler.Suspend_Until (Time_Stamp);
      --  XXX Check for Time_Stamp in the past need to be added.

      Request_PendSV;
      --  Request PendVS exception.
   end Delay_Until;

   -----------------
   -- Idle_Thread --
   -----------------

   procedure Idle_Thread is
   begin
      loop
         Wait_For_Interrupt;
      end loop;
   end Idle_Thread;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Master_Stack_Size   : System.Storage_Elements.Storage_Count;
      Use_Processor_Clock : Boolean;
      Clock_Frequency     : A0B.Types.Unsigned_32)
   is
      Stack_Frame_Size : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Unsigned_32 (Context_Switching.Stack_Frame_Size);
      Power_Of_Two     : constant Integer :=
        32 - Integer (A0B.Types.GCC_Builtins.clz (Stack_Frame_Size));
      Stack_Size       : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Shift_Left (1, Power_Of_Two);

   begin
      Next_Stack := estack'Address - Master_Stack_Size;

      Idle_Task_Control_Block.Stack :=
        Context_Switching.Initialize_Stack (Idle_Thread'Access, Next_Stack);
      Idle_Task_Control_Block.State := Idle;
      Idle_Task_Control_Block.Next  := System.Null_Address;

      Next_Stack :=
        @ - System.Storage_Elements.Storage_Offset (Stack_Size);

      System_Timer.Initialize_Timer (Use_Processor_Clock, Clock_Frequency);
   end Initialize;

   ---------------------
   -- Register_Thread --
   ---------------------

   procedure Register_Thread
     (Control_Block : aliased in out Task_Control_Block;
      Thread        : Task_Subprogram;
      Stack_Size    : System.Storage_Elements.Storage_Count)
   is
      use type System.Address;

   begin
      Control_Block.Stack :=
        Context_Switching.Initialize_Stack (Thread, Next_Stack);
      Control_Block.State := Runnable;
      Control_Block.Next  := System.Null_Address;

      Next_Stack := @ - Stack_Size;

      Scheduler.Run_Task (Control_Block'Unchecked_Access);
   end Register_Thread;

   --------------------
   -- Request_PendSV --
   --------------------

   procedure Request_PendSV is
   begin
      --  Request PendVS exception. Do synchronization after modification of
      --  the register in the System Control Space to avoid side effects.

      SCB.ICSR := (PENDSVSET => True, others => <>);
      Data_Synchronization_Barrier;
      Instruction_Synchronization_Barrier;
   end Request_PendSV;

   ---------
   -- Run --
   ---------

   procedure Run is
      use type A0B.Types.Unsigned_2;

      CPACR   : constant SCB_CPACR_Register := SCB.CPACR;
      Has_FPU : constant Boolean := (CPACR.CP10 /= 0) and (CPACR.CP11 /= 0);

   begin
      System_Timer.Enable_Timer;

      SCB.SHPR (A0B.ARMv7M.SVCall_Exception)  := SVCall_Priority;
      SCB.SHPR (A0B.ARMv7M.PendSV_Exception)  := PendSV_Priority;
      SCB.SHPR (A0B.ARMv7M.SysTick_Exception) := SysTick_Priority;
      --  Set priorities of system exceptions.

      if Has_FPU then
         declare
            CONTROL : CONTROL_Register := Get_CONTROL;

         begin
            CONTROL.FPCA := False;
            --  Clear FP execution bit, to use basic format of the exception
            --  frame. It is expected by SVC call to run the first task.

            Set_CONTROL (CONTROL);

            SCB_FP.FPCCR.LSPEN := True;
            --  Enable lazy save of the FPU context on interrupts.
         end;
      end if;

      --  Content of the master stack is not needed anymore, so reset MSP to
      --  the initial value. All preempted and pending interrupts should be
      --  completed first to be able to do this safely, so first reset
      --  priority boosting and enable all interrupts/faults.

      Set_BASEPRI (0);
      Instruction_Synchronization_Barrier;
      --  Reset priority boosting and ensure that priority is applied.

      Enable_Interrupts;
      Enable_Faults;
      --  Enable interrupts and faults.

      Set_MSP (estack'Address);
      --  Reset master stack to the initial value. It is safe do to here:
      --   - immidiately before the call of SVC to start first thread, so it
      --     will not be modified or older stored values are used by the
      --     current subprogram;
      --   - processor runs in Thread Mode without priority boosting, so
      --     there is no preempted exceptions at this point, thus nothing
      --     outside of this subprogram use this code.

      System.Machine_Code.Asm
        (Template => "svc 0",
         Volatile => True);
      --  Call SVC to start first thread. It never returns.

      raise Program_Error;
   end Run;

   ------------------------
   -- Suspend_Until_True --
   ------------------------

   procedure Suspend_Until_True (SO : aliased in out Suspension_Object) is
   begin
      Scheduler.Suspend_Until (SO);

      Request_PendSV;
      --  Request PendVS exception.
   end Suspend_Until_True;

   ---------------------------------------
   -- Suspend_Until_True_Or_Delay_Until --
   ---------------------------------------

   --  procedure Suspend_Until_True_Or_Delay_Until
   --    (SO   : in out Suspension_Object;
   --     Till : A0B.Types.Unsigned_64) is
   --  begin
   --     null;
   --  end Suspend_Until_True_Or_Delay_Until;

end A0B.Tasking;
