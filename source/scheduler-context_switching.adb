
pragma Restrictions (No_Elaboration_Code);

with System.Machine_Code;

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;

package body Scheduler.Context_Switching is

  --   procedure PendSV_Handler
  --     with Export, Convention => C, External_Name => "PendSV_Handler";
  --   --, No_Return;

  --   procedure Dummy is null;

   ------------------
   -- Save_Context --
   ------------------

   procedure Save_Context is
      NL    : constant Character := ASCII.LF;
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

   ---------------------
   -- Restore_Context --
   ---------------------

   procedure Restore_Context is
      NL    : constant Character := ASCII.LF;
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

  --   --------------------
  --   -- PendSV_Handler --
  --   --------------------

  --   procedure PendSV_Handler is
  --      LF    : constant Character := ASCII.LF;

  --      --  Stack : System.Address := Current_Task.Stack;
  --      Stack : System.Address;

  --   begin
  --      --  Get Process Stack Pointer register. It is position of the
  --      --  interrupted task: PendSV has lowerest priority level and can't
  --      --  preempt any interrupts.

  --    --    Stack := Get_PSP;

  --    --    --  Store S16-S31 registers when necessary, then store R4-R11 and LR
  --    --    --  registers.

  --    --    System.Machine_Code.Asm
  --    --      (Template =>
  --    --         "tst lr, #0x10" & LF
  --    --         & "it eq" & LF
  --    --         & "vstmdbeq %0!, {s16-s31}" & LF
  --    --         & "stmdb %0!, {r4-r11, lr}",
  --    --       Outputs  => System.Address'Asm_Output ("=r", Stack),
  --    --       Inputs   => System.Address'Asm_Input ("r", Stack),
  --    --       --  Clobber  => "memory",
  --    --       Volatile => True);

  --    --    --  Save stack pointer of the currently running task.

  --    --    Current_Task.Stack := Stack;

  --      --  XXX Schedule next task.

  --      Save_Context;

  --      --  Reschedule;

  --      Restore_Context;
  --      --  Load stack pointer of the task to be run.

  --    --    Stack := Current_Task.Stack;

  --      --  Restore R4-R11, LR (and S16-S31 when necessary) registers, setup
  --      --  PSP register and return.

  --    --    System.Machine_Code.Asm
  --    --      (Template =>
  --    --         "ldmia %0!, {r4-r11, lr}" & LF
  --    --         & "tst lr, #0x10" & LF
  --    --         & "it eq" & LF
  --    --         & "vldmiaeq %0!, {s16-s31}",
  --    --       Outputs  => System.Address'Asm_Output ("=r", Stack),
  --    --       Inputs   => System.Address'Asm_Input ("r", Stack),
  --    --       Volatile => True);
  --    --    Set_PSP (Stack);
  --   end PendSV_Handler;

end Scheduler.Context_Switching;