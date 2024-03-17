--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This is version for ARMv7-M CPU without FPU extension

separate (A0B.Tasking.Context_Switching)
procedure Restore_Context is
   Stack : System.Address;

begin
   --  Load stack pointer of the task to be run.

   Stack := Current_Task.Stack;

   --  Restore R4-R11, LR registers, setup PSP register and return.

   System.Machine_Code.Asm
     (Template => "ldmia %0!, {r4-r11, lr}",
      Outputs  => System.Address'Asm_Output ("=r", Stack),
      Inputs   => System.Address'Asm_Input ("r", Stack),
      Volatile => True);
   Set_PSP (Stack);
end Restore_Context;