
pragma Ada_2022;

with A0B.ARMv7M.Parameters;
with A0B.SVD.ATSAM3X8E.PIO; use A0B.SVD.ATSAM3X8E.PIO;
with A0B.Tasking;
with A0B.Types;

with P;

procedure LED_Tasking_Arduino_Due_Demo is
   use type A0B.Types.Unsigned_32;

begin
   A0B.ARMv7M.Parameters.CPU_Frequency     := 84_000_000;
   A0B.ARMv7M.Parameters.SysTick_Frequency :=
     A0B.ARMv7M.Parameters.CPU_Frequency / 2;
   --  Setup CPU and SysTick external clock frequency first.
   --
   --  XXX Should it be done by startup code? Or should be configurable in
   --  other way?
   --  XXX CPU clock frequency can be modified, thus SisTick will works
   --  incorrectly. Should MCU's timer be used for this purpose?

   PIOB_Periph.PER.Arr  := [27 => True, others => False];
   PIOB_Periph.OER.Arr  := [27 => True, others => False];
   PIOB_Periph.MDDR.Arr := [27 => True, others => False];

   A0B.Tasking.Initialize;
   A0B.Tasking.Register_Thread (P.On'Access);
   A0B.Tasking.Register_Thread (P.Off'Access);

   A0B.Tasking.Run;
end LED_Tasking_Arduino_Due_Demo;
