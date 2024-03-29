--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Tasking;

with LED_Blink;

procedure LED_Tasking_Arduino_Due_Demo is
begin
   A0B.Tasking.Initialize (16#200#, True, 84_000_000);
   --  512 bytes of the master stack are enough for this simple application.
   --  Use CPU clock as source for SysTick timer, CPU run at 84 MHz.

   LED_Blink.Initialize;
   --  Initialize tasks.

   A0B.Tasking.Run;
   --  Run registered tasks.
end LED_Tasking_Arduino_Due_Demo;
