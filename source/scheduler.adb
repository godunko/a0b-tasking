
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
      SYST.CSR := (ENABLE         => True,  --  Enable timer
                   TICKINT        => True,  --  Enable interrupt
                   CLKSOURCE      => True,  --  Use CPU clock
                  --   CLKSOURCE      => False,
                  --   COUNTFLAG      => <>,
                   others    => <>);
      --  ??? Setup NVIC priority ???

      --  ??? Configure lazy FPU context save when FPU is enabled.
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
      CONTROL : CONTROL_Register := Get_CONTROL;

   begin
      Initialize_Timer;

      if Has_FPU then
         CONTROL.FPCA := False;
         --  Clear FP execution bit, to use basic format of the exception
         --  frame. It is expected by SVC call to run the first task.

         SCB_FP.FPCCR.LSPEN := True;
         --  Enable lazy save of the FPU context on interrupts.
      end if;

      --  CONTROL.nPRIV := True;  --  Switch to unprivileged mode.
      --  XXX How to switch to unprivileged mode?
      Set_CONTROL (CONTROL);
      Instruction_Synchronization_Barrier;
      --  Required after change of the CONTROL register.

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