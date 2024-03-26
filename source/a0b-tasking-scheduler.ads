--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package A0B.Tasking.Scheduler is

   procedure Switch_Current_Task;
   --  Called by PendSV handler to switch current task.

end A0B.Tasking.Scheduler;