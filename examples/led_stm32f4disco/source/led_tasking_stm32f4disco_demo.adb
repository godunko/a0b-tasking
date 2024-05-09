--
--  Copyright (C) 2024, Yuri Veretelnikov <yuri.veretelnikov@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Tasking;

with LED_Blink;

procedure LED_Tasking_STM32F4DISCO_Demo is
begin
   A0B.Tasking.Initialize (16#200#, True, 168_000_000);
   --  512 bytes of the master stack are enough for this simple application.
   --  Use CPU clock as source for SysTick timer
   --  STM32F4 CPU runs at 168 (max)

   LED_Blink.Initialize;
   --  Initialize tasks.

   A0B.Tasking.Run;
   --  Run registered tasks.
end LED_Tasking_STM32F4DISCO_Demo;
