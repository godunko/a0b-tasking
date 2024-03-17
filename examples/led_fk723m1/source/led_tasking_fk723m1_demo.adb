
pragma Ada_2022;

with A0B.SVD.STM32H723.GPIO;  use A0B.SVD.STM32H723.GPIO;
with A0B.SVD.STM32H723.RCC;   use A0B.SVD.STM32H723.RCC;
with A0B.Tasking;

with P;

procedure Demo is
begin
   A0B.Tasking.Initialize;
   A0B.Tasking.Register_Thread (P.On'Access);
   A0B.Tasking.Register_Thread (P.Off'Access);

   RCC_Periph.AHB4ENR.GPIOGEN := True;
   GPIOG_Periph.MODER.Arr (7) := 1;

   A0B.Tasking.Run;
end Demo;