
pragma Ada_2022;

with Ada.Real_Time;

with A0B.SVD.STM32H723.GPIO; use A0B.SVD.STM32H723.GPIO;

package body P is

   use type Ada.Real_Time.Time;

   procedure Last_Chance_Handler is null
     with Export, Convention => C, Link_Name => "__gnat_last_chance_handler";

   ---------
   -- Off --
   ---------

   procedure Off is
      Offset   : constant Ada.Real_Time.Time_Span :=
        Ada.Real_Time.Milliseconds (500);
      Interval : constant Ada.Real_Time.Time_Span :=
        Ada.Real_Time.Milliseconds (1_000);
      C        : Ada.Real_Time.Time := Ada.Real_Time.Clock + Offset;

   begin
      loop
         delay until C;
         C := @ + Interval;

         GPIOG_Periph.ODR.OD.Arr (7) := True;
      end loop;
   end Off;

   --------
   -- On --
   --------

   procedure On is
      Offset   : constant Ada.Real_Time.Time_Span :=
        Ada.Real_Time.Milliseconds (0);
      Interval : constant Ada.Real_Time.Time_Span :=
        Ada.Real_Time.Milliseconds (1_000);
      C        : Ada.Real_Time.Time := Ada.Real_Time.Clock + Offset;

   begin
      loop
         delay until C;
         C := @ + Interval;

         GPIOG_Periph.ODR.OD.Arr (7) := False;
      end loop;
   end On;

end P;