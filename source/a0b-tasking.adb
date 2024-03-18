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
with A0B.ARMv7M.Parameters;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.ARMv7M.System_Timer;         use A0B.ARMv7M.System_Timer;
with A0B.Types;

with A0B.Tasking.Context_Switching;
with A0B.Tasking.Interrupt_Handling;

package body A0B.Tasking is

   procedure SysTick_Handler
     with Export, Convention => C, External_Name => "SysTick_Handler";

   Tick_Frequency : constant := 1_000;

   Next_Stack : System.Address;

   Idle_Stack_Size : constant := 16#100#;
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

   procedure Initialize_Thread
     (TCB    : in out Task_Control_Block;
      Thread : Thread_Subprogram;
      Stack  : System.Address);

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

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Master_Stack_Size : System.Storage_Elements.Storage_Count)
   is
      use type System.Address;

   begin
      Next_Stack := estack'Address - Master_Stack_Size;

      for J in Task_Table'Range loop
         Task_Table (J) :=
           (Stack => System.Null_Address,
            Id    => J,
            Time  => 0);
      end loop;

      Initialize_Thread
        (Task_Table (Task_Table'First), Idle_Thread'Access, Next_Stack);

      Next_Stack := @ - Idle_Stack_Size;
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

   -----------------------
   -- Initialize_Thread --
   -----------------------

   procedure Initialize_Thread
     (TCB    : in out Task_Control_Block;
      Thread : Thread_Subprogram;
      Stack  : System.Address) is
   begin
      TCB.Stack := Context_Switching.Initialize_Stack (Thread, Stack);
   end Initialize_Thread;

   ----------------
   -- Reschedule --
   ----------------

   procedure Reschedule is
      use type System.Address;

      pragma Suppress (All_Checks);
      --  use type A0B.Types.Unsigned_32;

      --  C : A0B.Types.Unsigned_32;
      C : constant Integer := Current_Task.Id;
      N : Integer          := C;

   begin
      --  for J in Task_Table'Range loop
      --     if Current_Task = Task_Table (J)'Access then
      --        C := J + 1;

      --        exit;
      --     end if;
      --  end loop;

      --  C := Current_Task.Id;

      loop
         N := @ + 1;

         if N > Task_Table'Last then
            N := Task_Table'First + 1;  --  First entry is idle thread.

            exit when C = Task_Table'First;
         end if;

         exit when N = C;

         exit when
           Task_Table (N).Stack /= System.Null_Address
             and then (Task_Table (N).Time = 0
                         or Task_Table (N).Time <= Clock);
      end loop;

      if Task_Table (N).Time /= 0 and Task_Table (N).Time > Clock then
         Current_Task := Task_Table (Task_Table'First)'Access;
         --  Run idle task

      else
         Task_Table (N).Time := 0;
         Current_Task := Task_Table (N)'Access;
      end if;
   end Reschedule;

   ---------------------
   -- Register_Thread --
   ---------------------

   procedure Register_Thread
     (Thread     : Thread_Subprogram;
      Stack_Size : System.Storage_Elements.Storage_Count)
   is
      use type System.Address;

   begin
      for T of Task_Table loop
         if T.Stack = System.Null_Address then
            Initialize_Thread (T, Thread, Next_Stack);
            exit;

         end if;
      end loop;

      Next_Stack := @ - Stack_Size;
   end Register_Thread;

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