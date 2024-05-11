--
--  Copyright (C) 2024, Yuri Veretelnikov <yuri.veretelnikov@gmail.com>>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.SVD.STM32F407.GPIO; use A0B.SVD.STM32F407.GPIO;
with A0B.SVD.STM32F407.RCC;  use A0B.SVD.STM32F407.RCC;

separate (LED_Blink)
package body Platform is

   ---------------
   -- Configure --
   ---------------

   procedure Configure is
   begin
      RCC_Periph.AHB1ENR.GPIODEN := True;
      GPIOD_Periph.MODER.Arr (13) := 1;
   end Configure;

   ---------
   -- Off --
   ---------

   procedure Off is
   begin
      GPIOD_Periph.BSRR.BS.Val := 02#0010_0000_0000_0000#;
   end Off;

   --------
   -- On --
   --------

   procedure On is
   begin
      GPIOD_Periph.BSRR.BR.Val := 02#0010_0000_0000_0000#;
   end On;

end Platform;