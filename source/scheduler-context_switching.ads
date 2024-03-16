
--  This package provides utilities for low level task context switching on
--  ARMv7-M CPUs (Cortex-M3/M4/M7 with/without FPU extension).
--
--  It is moved into own package to avoid dangerous inlining of the scheduler
--  subprogram from the PendSV_Handler.

pragma Restrictions (No_Elaboration_Code);

private package Scheduler.Context_Switching is

   function Initialize_Stack
     (Thread : Thread_Subprogram;
      Stack  : System.Address) return System.Address;
   --  Initialize stack to run task for the first time.

   procedure Save_Context with Inline_Always;
   --  Save task context

   procedure Restore_Context;
   --  Restore task context and jump to the task's code.

end Scheduler.Context_Switching;