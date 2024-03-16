
--  This package provides low level task context switching.
--
--  It is moved into own package to avoid dangerous inlining of the scheduler
--  subprogram from the PendSV_Handler.

pragma Restrictions (No_Elaboration_Code);

private package Scheduler.Context_Switching is

   procedure Save_Context with Inline_Always;
   --  Save task context

   procedure Restore_Context;
   --  Restore task context and jump to the task's code.

end Scheduler.Context_Switching;