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

   Overflow_Count : A0B.Types.Unsigned_64 := 0 with Volatile;
   --  Counter of the SysTick timer overflows multiplied by 1_000, thus it is
   --  base monotonic time for current tick in microseconds.

   Millisecond_Ticks : A0B.Types.Unsigned_32;
   Microsecond_Ticks : A0B.Types.Unsigned_32;
   --  Number of the timer's ticks in one microsecond.

   -----------
   -- Clock --
   -----------

   function Clock return A0B.Types.Unsigned_64 is
      use type A0B.Types.Unsigned_64;

      Result   : A0B.Types.Unsigned_64;
      CURRENT1 : A0B.Types.Unsigned_32;
      CURRENT2 : A0B.Types.Unsigned_32;

   begin
      Disable_Interrupts;

      loop
         CURRENT1 := SYST.CVR.CURRENT;

         if SYST.CSR.COUNTFLAG then
            Overflow_Count := @ + 1_000;
            CURRENT2   := SYST.CVR.CURRENT;

            exit;

         else
            Result   := Overflow_Count;
            CURRENT2 := SYST.CVR.CURRENT;

            exit when CURRENT2 < CURRENT1;
         end if;
      end loop;

      Enable_Interrupts;

      Result :=
        @ + A0B.Types.Unsigned_64
              ((Millisecond_Ticks - CURRENT2) / Microsecond_Ticks);

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
      SYST.CVR.CURRENT := 0;
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
      Disable_Interrupts;

      if SYST.CSR.COUNTFLAG then
         Overflow_Count := @ + 1_000;
      end if;

      Enable_Interrupts;
   end Overflow;

end A0B.Tasking.System_Timer;