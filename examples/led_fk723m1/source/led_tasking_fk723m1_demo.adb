
pragma Ada_2022;

with A0B.ARMv7M.Parameters;
with A0B.SVD.STM32H723.GPIO;  use A0B.SVD.STM32H723.GPIO;
with A0B.SVD.STM32H723.RCC;   use A0B.SVD.STM32H723.RCC;
with A0B.Tasking;
with A0B.Types;

with P;

procedure LED_Tasking_FK723M1_Demo is
   use type A0B.Types.Unsigned_32;

begin
   --  delay until Ada.Real_Time.Clock;

   A0B.ARMv7M.Parameters.CPU_Frequency     := 520_000_000;
   A0B.ARMv7M.Parameters.SysTick_Frequency :=
     A0B.ARMv7M.Parameters.CPU_Frequency / 8;
   --  Setup CPU and SysTick external clock frequency first.
   --
   --  XXX Should it be done by startup code? Or should be configurable in
   --  other way?
   --  XXX CPU clock frequency can be modified, thus SisTick will works
   --  incorrectly. Should MCU's timer be used for this purpose?

   A0B.Tasking.Initialize (16#200#, True, 520_000_000);
   --  512 bytes of the master stack are enough for this simple application.
   A0B.Tasking.Register_Thread (P.On_Task, P.On'Access, 16#100#);
   A0B.Tasking.Register_Thread (P.Off_Task, P.Off'Access, 16#100#);

   RCC_Periph.AHB4ENR.GPIOGEN := True;
   GPIOG_Periph.MODER.Arr (7) := 1;

   A0B.Tasking.Run;
end LED_Tasking_FK723M1_Demo;