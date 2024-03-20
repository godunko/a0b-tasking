--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package provides utilities for low level task context switching on
--  ARMv7-M CPUs (Cortex-M3/M4/M7 with/without FPU extension).
--
--  It is moved into own package to avoid dangerous inlining of the scheduler
--  subprogram from the PendSV_Handler.

pragma Restrictions (No_Elaboration_Code);

private package A0B.Tasking.Context_Switching is

   function Initialize_Stack
     (Thread : Task_Subprogram;
      Stack  : System.Address) return System.Address;
   --  Initialize stack to run task for the first time.

   procedure Save_Context with Inline_Always;
   --  Save task context

   procedure Restore_Context;
   --  Restore task context and jump to the task's code.

   function Stack_Frame_Size return System.Storage_Elements.Storage_Count
     with Inline_Always;
   --  Return size of the stack to store context switch frame.

end A0B.Tasking.Context_Switching;