--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.SVD.STM32H723.GPIO; use A0B.SVD.STM32H723.GPIO;
with A0B.SVD.STM32H723.RCC;  use A0B.SVD.STM32H723.RCC;

separate (LED_Blink)
package body Platform is

   ---------------
   -- Configure --
   ---------------

   procedure Configure is
   begin
      RCC_Periph.AHB4ENR.GPIOGEN := True;
      GPIOG_Periph.MODER.Arr (7) := 1;
   end Configure;

   ---------
   -- Off --
   ---------

   procedure Off is
   begin
      GPIOG_Periph.ODR.OD.Arr (7) := True;
   end Off;

   --------
   -- On --
   --------

   procedure On is
   begin
      GPIOG_Periph.ODR.OD.Arr (7) := False;
   end On;

end Platform;