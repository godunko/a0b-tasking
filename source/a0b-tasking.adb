--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with System.Address_To_Access_Conversions;
with System.Machine_Code;
with System.Storage_Elements;         use System.Storage_Elements;

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.Parameters;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.ARMv7M.System_Timer;         use A0B.ARMv7M.System_Timer;
with A0B.Types.GCC_Builtins;

with A0B.Tasking.Context_Switching;
with A0B.Tasking.Interrupt_Handling;

package body A0B.Tasking is

   procedure SysTick_Handler
     with Export, Convention => C, External_Name => "SysTick_Handler";

   Tick_Frequency : constant := 1_000;

   Next_Stack : System.Address;

   --  Idle_Stack_Size : constant := 16#100#;
   --  Stack size of the idle task. Up to 204 bytes are necessary for the
   --  context switching, allign it to nearest power of two value.

   function To_Priority_Value
     (Item : Priority) return A0B.ARMv7M.Priority_Value is
       (A0B.ARMv7M.Priority_Value
         (Priority (A0B.ARMv7M.Priority_Value'Last) - Item));
   --  Conversion from abstract priority level to ARM priority value.

   estack : constant Interfaces.Unsigned_64
     with Import, Convention => C, External_Name => "_estack";

   procedure Idle_Thread;
   --  Thread that run idle loop.

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (Time_Stamp : Unsigned_32) is
   begin
      --  Update task control block.

      Current_Task.Time := Time_Stamp;

      --  Request PendVS exception. Do synchronization after modification of
      --  the register in the System Control Space to avoid side effects.

      SCB.ICSR := (PENDSVSET => True, others => <>);
      Data_Synchronization_Barrier;
      Instruction_Synchronization_Barrier;
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

   package TCB_Conversion is
     new System.Address_To_Access_Conversions (Task_Control_Block);

   function To_Address (Item : Task_Control_Block_Access) return System.Address is
   begin
      return TCB_Conversion.To_Address (TCB_Conversion.Object_Pointer (Item));
   end To_Address;

   function To_Pointer (Item : System.Address) return Task_Control_Block_Access is
   begin
      return Task_Control_Block_Access (TCB_Conversion.To_Pointer (Item));
   end To_Pointer;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Master_Stack_Size : System.Storage_Elements.Storage_Count)
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
      Idle_Task_Control_Block.Next :=
        To_Address (Idle_Task_Control_Block'Access);

      Next_Stack :=
        @ - System.Storage_Elements.Storage_Offset (Stack_Size);
   end Initialize;

   ----------------------
   -- Initialize_Timer --
   ----------------------

   procedure Initialize_Timer is
      use type A0B.Types.Unsigned_32;

      Reload_Value : constant A0B.Types.Unsigned_32 :=
        (A0B.ARMv7M.Parameters.CPU_Frequency / Tick_Frequency) - 1;

   begin
      SYST.RVR.RELOAD    := A0B.Types.Unsigned_24 (Reload_Value);
      SYST.CVR.CURRENT   := 0;
      SYST.CSR := (ENABLE    => True,  --  Enable timer
                   TICKINT   => True,  --  Enable interrupt
                   CLKSOURCE => True,  --  Use CPU clock
                   others    => <>);
   end Initialize_Timer;

   ---------------------
   -- Register_Thread --
   ---------------------

   procedure Register_Thread
     (Control_Block : aliased in out Task_Control_Block;
      Thread        : Task_Subprogram;
      Stack_Size    : System.Storage_Elements.Storage_Count)
   is
      use type System.Address;

      Last_Task : Task_Control_Block_Access := Idle_Task_Control_Block'Access;

   begin
      --  for T of Task_Table loop
      --     if T.Stack = To_Integer (System.Null_Address) then
      --        T.Stack :=
      --          To_Integer
      --            (Context_Switching.Initialize_Stack (Thread, Next_Stack));

      --        exit;
      --     end if;
      --  end loop;

      loop
         exit when Last_Task.Next
                     = To_Address (Idle_Task_Control_Block'Access);

         Last_Task := To_Pointer (Last_Task.Next);
      end loop;

      Control_Block.Next  := Last_Task.Next;
      Control_Block.Stack :=
        Context_Switching.Initialize_Stack (Thread, Next_Stack);
      Last_Task.Next      := To_Address (Control_Block'Unchecked_Access);

      Next_Stack := @ - Stack_Size;
   end Register_Thread;

   ----------------
   -- Reschedule --
   ----------------

   procedure Reschedule is
      use type System.Address;

      pragma Suppress (All_Checks);
      --  use type A0B.Types.Unsigned_32;

      --  C : A0B.Types.Unsigned_32;
      --  C : constant Integer := Current_Task.Id;
      --  N : Integer          := C;

      Next_Task : Task_Control_Block_Access := Current_Task;

   begin
      --  for J in Task_Table'Range loop
      --     if Current_Task = Task_Table (J)'Access then
      --        C := J + 1;

      --        exit;
      --     end if;
      --  end loop;

      --  C := Current_Task.Id;

      loop
         Next_Task := To_Pointer (Next_Task.Next);

         --  if Next_Task = null then
         --     Next_Task := Idle_Task_Control_Block.Next;

         --     exit when Current_Task = Idle_Task_Control_Block;
         --  end if;

         exit when Next_Task = Current_Task;

         if Next_Task /= Idle_Task_Control_Block'Access then
            --  exit when Next_Task.Time /= 0 and Next_Task.Time <= Clock;
            exit when Next_Task.Time <= Clock;
         end if;
      end loop;
      --  loop
      --     N := @ + 1;

      --     if N > Task_Table'Last then
      --        N := Task_Table'First + 1;  --  First entry is idle thread.

      --        exit when C = Task_Table'First;
      --     end if;

      --     exit when N = C;

      --     exit when
      --       Task_Table (N).Stack /= To_Integer (System.Null_Address)
      --         and then (Task_Table (N).Time = 0
      --                     or Task_Table (N).Time <= Clock);
      --  end loop;

      if Next_Task.Time /= 0 and Next_Task.Time > Clock then
         Current_Task   := Idle_Task_Control_Block'Access;
         --  Run idle task

      else
         Next_Task.Time := 0;
         Current_Task   := Next_Task;
      end if;

      --  if Task_Table (N).Time /= 0 and Task_Table (N).Time > Clock then
      --     Current_Task := Task_Table (Task_Table'First)'Access;
      --     --  Run idle task

      --  else
      --     Task_Table (N).Time := 0;
      --     Current_Task := Task_Table (N)'Access;
      --  end if;
   end Reschedule;

   ---------
   -- Run --
   ---------

   procedure Run is
      use type A0B.Types.Unsigned_2;

      CPACR   : constant SCB_CPACR_Register := SCB.CPACR;
      Has_FPU : constant Boolean := (CPACR.CP10 /= 0) and (CPACR.CP11 /= 0);

   begin
      Initialize_Timer;

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

      System.Machine_Code.Asm
        (Template => "cpsie i",
         Volatile => True);
      System.Machine_Code.Asm
        (Template => "cpsie f",
         Volatile => True);
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
   end Run;

   ---------------------
   -- SysTick_Handler --
   ---------------------

   procedure SysTick_Handler is
   begin
      --  if Switch then
         --  Switch   := False;
         SCB.ICSR := (PENDSVSET => True, others => <>);
         --  Request PendSV exception to switch context
      --  end if;

      Clock := @ + 1;
   end SysTick_Handler;

end A0B.Tasking;
