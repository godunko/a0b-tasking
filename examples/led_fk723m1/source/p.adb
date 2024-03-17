
pragma Ada_2022;

with Interfaces;             use Interfaces;

with A0B.SVD.STM32H723.GPIO; use A0B.SVD.STM32H723.GPIO;

with A0B.Tasking;            use A0B.Tasking;

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

         --  if (Scheduler.Clock / 500) mod 2 = 1 then
         GPIOG_Periph.ODR.OD.Arr (7) := True;
         --  end if;
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

         --  if (Scheduler.Clock / 500) mod 2 = 0 then
         GPIOG_Periph.ODR.OD.Arr (7) := False;
         --  end if;
      end loop;
   end On;

end P;