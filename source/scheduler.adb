
pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with System.Machine_Code;
with System.Storage_Elements;         use System.Storage_Elements;

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.ARMv7M.System_Timer;         use A0B.ARMv7M.System_Timer;
with A0B.Types;

with Scheduler.Context_Switching;
with Scheduler.Interrupt_Handling;

package body Scheduler is

   procedure SysTick_Handler
     with Export, Convention => C, External_Name => "SysTick_Handler";

   CPU_Frequency  : constant := 520_000_000;
   Tick_Frequency : constant := 1_000;
   Reload_Value   : constant := (CPU_Frequency / Tick_Frequency) - 1;

   Next_Stack : System.Address;

   Stack_Size : constant := 16#1000#;

   function To_Priority_Value
     (Item : Priority) return A0B.ARMv7M.Priority_Value is
       (A0B.ARMv7M.Priority_Value
         (Priority (A0B.ARMv7M.Priority_Value'Last) - Item));
   --  Conversion from abstract priority level to ARM priority value.

   estack : constant Interfaces.Unsigned_64
     with Import, Convention => C, External_Name => "_estack";

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (Time_Stamp : Unsigned_32) is
   begin
      while Clock < Time_Stamp loop
         null;
      end loop;
   end Delay_Until;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Next_Stack := estack'Address - Stack_Size;

      for J in Task_Table'Range loop
         Task_Table (J) := (Stack => System.Null_Address, Id => J);
      end loop;
   end Initialize;

   ----------------------
   -- Initialize_Timer --
   ----------------------

   procedure Initialize_Timer is
   begin
      SYST.RVR.RELOAD    := Reload_Value;
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
      C : Integer;

   begin
      --  for J in Task_Table'Range loop
      --     if Current_Task = Task_Table (J)'Access then
      --        C := J + 1;

      --        exit;
      --     end if;
      --  end loop;

      C := Current_Task.Id;

      loop
         C := @ + 1;

         if C > Task_Table'Last then
            C := Task_Table'First;
         end if;

         exit when Task_Table (C).Stack /= System.Null_Address;
      end loop;

      Current_Task := Task_Table (C)'Access;
   end Reschedule;

   ---------------------
   -- Register_Thread --
   ---------------------

   procedure Register_Thread (Thread : Thread_Subprogram) is
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

end Scheduler;