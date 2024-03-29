--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Real_Time;

with A0B.SVD.ATSAM3X8E.PIO; use A0B.SVD.ATSAM3X8E.PIO;

separate (LED_Blink)
package body Platform is

   ---------------
   -- Configure --
   ---------------

   procedure Configure is
   begin
      PIOB_Periph.PER.Arr  := [27 => True, others => False];
      PIOB_Periph.OER.Arr  := [27 => True, others => False];
      PIOB_Periph.MDDR.Arr := [27 => True, others => False];
   end Configure;

   ---------
   -- Off --
   ---------

   procedure Off is
   begin
      PIOB_Periph.CODR.Arr := [27 => True, others => False];
   end Off;

   --------
   -- On --
   --------

   procedure On is
   begin
      PIOB_Periph.SODR.Arr := [27 => True, others => False];
   end On;

end Platform;
