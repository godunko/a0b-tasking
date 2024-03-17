--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This is version for ARMv7-M CPU with FPU extension

separate (A0B.Tasking.Context_Switching)
procedure Restore_Context is
   Stack : System.Address;

begin
   --  Load stack pointer of the task to be run.

   Stack := Current_Task.Stack;

   --  Restore R4-R11, LR (and S16-S31 when necessary) registers, setup
   --  PSP register and return.

   System.Machine_Code.Asm
     (Template =>
        "ldmia %0!, {r4-r11, lr}" & NL
        & "tst lr, #0x10" & NL
        & "it eq" & NL
        & "vldmiaeq %0!, {s16-s31}",
      Outputs  => System.Address'Asm_Output ("=r", Stack),
      Inputs   => System.Address'Asm_Input ("r", Stack),
      Volatile => True);
   Set_PSP (Stack);
end Restore_Context;