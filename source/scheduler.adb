
pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with Ada.Unchecked_Conversion;
with System.Machine_Code;
with System.Storage_Elements;         use System.Storage_Elements;

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.ARMv7M.System_Timer;         use A0B.ARMv7M.System_Timer;
with A0B.Types;

with Scheduler.Context_Switching;
with Scheduler.interrupt_Handling;

package body Scheduler is

   procedure SysTick_Handler
     with Export, Convention => C, External_Name => "SysTick_Handler";

   CPU_Frequency  : constant := 520_000_000;
   Tick_Frequency : constant := 1_000;
   Reload_Value   : constant := (CPU_Frequency / Tick_Frequency) - 1;

   Next_Stack : System.Address;

   Stack_Size : constant := 16#1000#;

   type ARMv7_Exception_Basic_Frame is record
      R0   : A0B.Types.Unsigned_32 := 0;
      R1   : A0B.Types.Unsigned_32 := 0;
      R2   : A0B.Types.Unsigned_32 := 0;
      R3   : A0B.Types.Unsigned_32 := 0;
      R12  : A0B.Types.Unsigned_32 := 0;
      LR   : A0B.Types.Unsigned_32 := 16#FFFFFFFF#;
      PC   : System.Address;
      xPSR : A0B.Types.Unsigned_32 := 16#0100_0000#;  --  Thumb mode
   end record with Object_Size => 256, Alignment => 8;

   type ARMv7_Exception_Extended_Frame is record
      R0       : A0B.Types.Unsigned_32 := 0;
      R1       : A0B.Types.Unsigned_32 := 1;
      R2       : A0B.Types.Unsigned_32 := 2;
      R3       : A0B.Types.Unsigned_32 := 3;
      R12      : A0B.Types.Unsigned_32 := 12;
      LR       : A0B.Types.Unsigned_32 := 16#FFFFFFFF#;
      PC       : System.Address;
      xPSR     : A0B.Types.Unsigned_32 := 16#0100_0000#;  --  Thumb mode
      S0       : A0B.Types.Unsigned_32 := 0;
      S1       : A0B.Types.Unsigned_32 := 1;
      S2       : A0B.Types.Unsigned_32 := 2;
      S3       : A0B.Types.Unsigned_32 := 3;
      S4       : A0B.Types.Unsigned_32 := 4;
      S5       : A0B.Types.Unsigned_32 := 5;
      S6       : A0B.Types.Unsigned_32 := 6;
      S7       : A0B.Types.Unsigned_32 := 7;
      S8       : A0B.Types.Unsigned_32 := 8;
      S9       : A0B.Types.Unsigned_32 := 9;
      S10      : A0B.Types.Unsigned_32 := 10;
      S11      : A0B.Types.Unsigned_32 := 11;
      S12      : A0B.Types.Unsigned_32 := 12;
      S13      : A0B.Types.Unsigned_32 := 13;
      S14      : A0B.Types.Unsigned_32 := 14;
      S15      : A0B.Types.Unsigned_32 := 15;
      FPSCR    : A0B.Types.Unsigned_32 := 0;
      Reserved : A0B.Types.Unsigned_32 := 0;
   end record with Object_Size => 832, Alignment => 8;

   type Context_Switch_Basic_Frame is record
      R4       : A0B.Types.Unsigned_32 := 0;
      R5       : A0B.Types.Unsigned_32 := 0;
      R6       : A0B.Types.Unsigned_32 := 0;
      R7       : A0B.Types.Unsigned_32 := 0;
      R8       : A0B.Types.Unsigned_32 := 0;
      R9       : A0B.Types.Unsigned_32 := 0;
      R10      : A0B.Types.Unsigned_32 := 0;
      R11      : A0B.Types.Unsigned_32 := 0;
      LR       : A0B.Types.Unsigned_32 := 16#FFFF_FFFD#;
      --  Return to thread mode, PSP, no FPU state
   end record with Object_Size => 288, Alignment => 4;

   type Context_Switch_Extended_Frame is record
      R4       : A0B.Types.Unsigned_32 := 4;
      R5       : A0B.Types.Unsigned_32 := 5;
      R6       : A0B.Types.Unsigned_32 := 6;
      R7       : A0B.Types.Unsigned_32 := 7;
      R8       : A0B.Types.Unsigned_32 := 8;
      R9       : A0B.Types.Unsigned_32 := 9;
      R10      : A0B.Types.Unsigned_32 := 10;
      R11      : A0B.Types.Unsigned_32 := 11;
      LR       : A0B.Types.Unsigned_32 := 16#FFFF_FFED#;
      --  Return to thread mode, PSP, restore FPU state
      S16      : A0B.Types.Unsigned_32 := 16;
      S17      : A0B.Types.Unsigned_32 := 17;
      S18      : A0B.Types.Unsigned_32 := 18;
      S19      : A0B.Types.Unsigned_32 := 19;
      S20      : A0B.Types.Unsigned_32 := 20;
      S21      : A0B.Types.Unsigned_32 := 21;
      S22      : A0B.Types.Unsigned_32 := 22;
      S23      : A0B.Types.Unsigned_32 := 23;
      S24      : A0B.Types.Unsigned_32 := 24;
      S25      : A0B.Types.Unsigned_32 := 25;
      S26      : A0B.Types.Unsigned_32 := 26;
      S27      : A0B.Types.Unsigned_32 := 27;
      S28      : A0B.Types.Unsigned_32 := 28;
      S29      : A0B.Types.Unsigned_32 := 29;
      S30      : A0B.Types.Unsigned_32 := 30;
      S31      : A0B.Types.Unsigned_32 := 31;
   end record with Object_Size => 800, Alignment => 4;

   --  Current_Task : not null Task_Control_Block_Access :=
   --    Task_Table (Task_Table'First)'Unchecked_Access with Volatile;

   INITIAL_EXC_RETURN : constant := 16#FFFF_FFFD#;
   --  Exception return value for the Link Register to run thread code for
   --  the first time. It means that processor will returns to Thread Mode,
   --  to use Process Stack Pointer, without restore of the FPU context.

   INITIAL_xPSR_VALUE : constant := 16#0100_0000#;
   --  Initial value of the xPSR register for starting thread. It means that
   --  Thumb instructions mode is enabled.

   LOCKUP_THREAD_RETURN : constant := 16#FFFF_FFFF#;
   --  Return value for the Link Register to switch processor into lockup
   --  state when thread subprogram returns.

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

   ARMv7_Basic_Frame_Length             : constant := 8;
   ARMv7_Extended_Frame_Length          : constant := 26;
   Context_Switch_Basic_Frame_Length    : constant := 9;
   Context_Switch_Extended_Frame_Length : constant := 25;
   ARMv7M_LR_Index                      : constant := 5;
   ARMv7M_PS_Index                      : constant := 6;
   ARMv7M_xPSR_Index                    : constant := 7;
   Context_Switch_LR_Index              : constant := 8;

   type Unsigned_32_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_32;

   procedure Initialize_Thread
     (TCB    : in out Task_Control_Block;
      Thread : Thread_Subprogram;
      Stack  : System.Address)
   is
      use type A0B.Types.Unsigned_32;

      Exception_Basic_Frame_Size      : constant :=
        ARMv7_Basic_Frame_Length
          * A0B.Types.Unsigned_32'Max_Size_In_Storage_Elements;
      Context_Switch_Basic_Frame_Size : constant :=
        Context_Switch_Basic_Frame_Length
          * A0B.Types.Unsigned_32'Max_Size_In_Storage_Elements;

      --  Save_SP : System.Address;
      --   Save_
      --  CONTROL : CONTROL_Register;

      function To_Address is
        new Ada.Unchecked_Conversion (Thread_Subprogram, System.Address);

      function To_Unsigned_32 is
        new Ada.Unchecked_Conversion
              (Thread_Subprogram, A0B.Types.Unsigned_32);

      --  Exception_Frame : ARMv7_Exception_Extended_Frame :=
      --    (PC     =>   --  Thread'Address,
      --     To_Address (Thread),
      --     others => <>)
      --    with Address =>
      --      Stack
      --        - ARMv7_Exception_Extended_Frame'Max_Size_In_Storage_Elements;
      --  Context_Switch_Frame : Context_Switch_Extended_Frame :=
      --    (others => <>)
      --    with Address =>
      --      Stack
      --        - ARMv7_Exception_Extended_Frame'Max_Size_In_Storage_Elements
      --        - Context_Switch_Extended_Frame'Max_Size_In_Storage_Elements;

      Exception_Frame      : Unsigned_32_Array (0 .. ARMv7_Basic_Frame_Length - 1)
        with Address =>
          Stack - Exception_Basic_Frame_Size;
      Context_Switch_Frame : Unsigned_32_Array (0 .. Context_Switch_Basic_Frame_Length - 1)
        with Address =>
          Stack - Exception_Basic_Frame_Size - Context_Switch_Basic_Frame_Size;

   begin
      Exception_Frame      := (others => 0);
      Context_Switch_Frame := (others => 0);

      Exception_Frame (ARMv7M_LR_Index)   := LOCKUP_THREAD_RETURN;
      Exception_Frame (ARMv7M_PS_Index)   := To_Unsigned_32 (Thread);
      Exception_Frame (ARMv7M_xPSR_Index) := INITIAL_xPSR_VALUE;

      Context_Switch_Frame (Context_Switch_LR_Index) := INITIAL_EXC_RETURN;

      TCB.Stack := Context_Switch_Frame'Address;
      --  Switch             := True;
      --  CONTROL := Get_CONTROL;
      --  System.Machine_Code.Asm
      --    (Template => "mov %0, sp",
      --     Outputs  => System.Address'Asm_Output ("=r", Save_SP));

      --  --  System.Machine_Code.Asm
      --  --    (Template => "msr control, %0" & ASCII.LF,
      --  --     Outputs  => CONTROL_Register'Asm_Output ("=r", CONTROL),
      --  --     Volatile => True);
      --  CONTROL.SPSEL := True;

      --  Set_PSP (Stack);
      --  Set_CONTROL (CONTROL);
      --  Instruction_Synchronization_Barrier;
      --  --  System.Machine_Code.Asm
      --  --  --    (Template => "mov sp, %0",
      --  --    (Template => "mrs %0, msp",
      --  --     Inputs   => System.Address'Asm_Input ("r", Stack),
      --  --     Clobber  => "memory",
      --  --     Volatile => True);
      --  --  System.Machine_Code.Asm
      --  --    (Template => "mrs control, %0",
      --  --     Inputs   => CONTROL_Register'Asm_Input ("r", CONTROL),
      --  --     Clobber  => "memory",
      --  --     Volatile => True);
      --  --  System.Machine_Code.Asm
      --  --    (Template => "msr %0, control",
      --  --     Outputs  => CONTROL_Register'Asm_Output ("=r", CONTROL));

      --  System.Machine_Code.Asm
      --    (Template => "svc 0",
      --     Volatile => True);

      --  System.Machine_Code.Asm
      --    (Template => "mov sp, %0",
      --     Inputs   => System.Address'Asm_Input ("r", Save_SP),
      --     Clobber  => "memory",
      --     Volatile => True);
   end Initialize_Thread;

   --  procedure Reschedule with Inline => False;
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