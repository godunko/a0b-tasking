--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with A0B.ARMv7M.CMSIS;        use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.System_Timer; use A0B.ARMv7M.System_Timer;

package body A0B.Tasking.System_Timer is

   Tick_Frequency : constant := 1_000;

   One_Millisecond : constant := 1_000_000;

   Overflow_Counter  : A0B.Types.Unsigned_64 := 0;
   --    with Volatile, Linker_Section => ".dtcm.data";
   --  Counter of the SysTick timer overflows multiplied by 1_000, thus it is
   --  base monotonic time for current tick in microseconds.

   Millisecond_Ticks : A0B.Types.Unsigned_32;
   --    with Linker_Section => ".dtcm.data";
   Microsecond_Ticks : A0B.Types.Unsigned_32;
   --    with Linker_Section => ".dtcm.data";
   --  Number of the timer's ticks in one microsecond.

   -----------
   -- Clock --
   -----------

   function Clock return A0B.Types.Unsigned_64 is
      pragma Suppress (Division_Check);
      --  Suppress division by zero check, Microsecond_Ticks must not be equal
      --  to zero when configured properly.

      use type A0B.Types.Unsigned_64;

      Result       : A0B.Types.Unsigned_64;
      CURRENT      : A0B.Types.Unsigned_32;
      Microseconds : A0B.Types.Unsigned_32;

   begin
      --  SysTick timer interrupt has lowerst priority, thus can be handled
      --  only when there is no another higher priority tasks/interrupts.
      --  However, Clock subprogram can be called by the task with any
      --  priority, thus global Overflow_Count object might be not updated
      --  yet. So, it is updated here. Interrupts are disabled to make sure
      --  that no other higher priority task do update.

      Disable_Interrupts;

      CURRENT := SYST.CVR.CURRENT;
      Result  := Overflow_Counter;

      if SYST.CSR.COUNTFLAG then
         Result           := @ + One_Millisecond;
         Overflow_Counter := Result;
      end if;

      Enable_Interrupts;

      Microseconds := (Millisecond_Ticks - CURRENT) / Microsecond_Ticks;
      Result       := @ + A0B.Types.Unsigned_64 (Microseconds * 1_000);

      return Result;
   end Clock;

   ------------------
   -- Enable_Timer --
   ------------------

   procedure Enable_Timer is
      Aux : SYST_CSR_Register := SYST.CSR;

   begin
      Aux.ENABLE  := True;
      Aux.TICKINT := True;

      SYST.CSR    := Aux;
   end Enable_Timer;

   ----------------------
   -- Initialize_Timer --
   ----------------------

   procedure Initialize_Timer
     (Use_Processor_Clock : Boolean;
      Clock_Frequency     : A0B.Types.Unsigned_32)
   is
      Reload_Value : A0B.Types.Unsigned_32;

   begin
      Millisecond_Ticks := Clock_Frequency / Tick_Frequency;
      Microsecond_Ticks := Millisecond_Ticks / 1_000;
      Reload_Value      := Millisecond_Ticks - 1;

      SYST.RVR.RELOAD  := A0B.Types.Unsigned_24 (Reload_Value);
      SYST.CVR.CURRENT := 0;  --  Any write operation resets value to zero.
      SYST.CSR :=
        (ENABLE    => False,                --  Enable timer
         TICKINT   => False,                --  Enable interrupt
         CLKSOURCE => Use_Processor_Clock,  --  Use CPU clock
         others    => <>);
   end Initialize_Timer;

   --------------
   -- Overflow --
   --------------

   procedure Overflow is
      use type A0B.Types.Unsigned_64;

   begin
      --  This subprogram is called from the SysTick handler, which has
      --  lowerst priority, thus can be preempted by any task/interrupt
      --  which can call Clock function. Disable interrupts till update
      --  of the overflow counter, and check whether overflow has been
      --  processed by higher priority task/interrupt before update of
      --  the counter.

      Disable_Interrupts;

      if SYST.CSR.COUNTFLAG then
         Overflow_Counter := @ + One_Millisecond;
      end if;

      Enable_Interrupts;
   end Overflow;

   ----------------
   -- Tick_Clock --
   ----------------

   function Tick_Base return A0B.Types.Unsigned_64 is
   begin
      return Overflow_Counter;
   end Tick_Base;

end A0B.Tasking.System_Timer;