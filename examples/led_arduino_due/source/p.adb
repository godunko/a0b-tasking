
pragma Ada_2022;

with Interfaces;            use Interfaces;

with A0B.SVD.ATSAM3X8E.PIO; use A0B.SVD.ATSAM3X8E.PIO;

with A0B.Tasking;           use A0B.Tasking;

package body P is

   ---------
   -- Off --
   ---------

   procedure Off is
      C : Unsigned_32 := Clock;

   begin
      loop
         C := @ + 1_000;
         Delay_Until (C);

         PIOB_Periph.CODR.Arr := [27 => True, others => False];
      end loop;
   end Off;

   --------
   -- On --
   --------

   procedure On is
      C : Unsigned_32 := Clock + 500;

   begin
      loop
         C := @ + 1_000;
         Delay_Until (C);

         PIOB_Periph.SODR.Arr := [27 => True, others => False];
      end loop;
   end On;

end P;
