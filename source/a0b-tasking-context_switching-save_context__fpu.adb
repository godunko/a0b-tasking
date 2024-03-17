--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This is version for ARMv7-M CPU with FPU extension

separate (A0B.Tasking.Context_Switching)
procedure Save_Context is
   Stack : System.Address;

begin
   --  Get Process Stack Pointer register. It is position of the
   --  interrupted task: PendSV has lowerest priority level and can't
   --  preempt any interrupts.

   Stack := Get_PSP;

   --  Store S16-S31 registers when necessary, then store R4-R11 and LR
   --  registers.

   System.Machine_Code.Asm
     (Template =>
        "tst lr, #0x10" & NL
        & "it eq" & NL
        & "vstmdbeq %0!, {s16-s31}" & NL
        & "stmdb %0!, {r4-r11, lr}",
      Outputs  => System.Address'Asm_Output ("=r", Stack),
      Inputs   => System.Address'Asm_Input ("r", Stack),
      Clobber  => "memory",
      Volatile => True);

   --  Save stack pointer of the currently running task.

   Current_Task.Stack := Stack;
end Save_Context;