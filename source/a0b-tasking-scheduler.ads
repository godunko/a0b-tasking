--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

private package A0B.Tasking.Scheduler is

   procedure Register_Task (TCB : not null Task_Control_Block_Access)
     with Pre => TCB.State = Runnable;
   --  Register task. Task must be in Runnable state.

   procedure Switch_Current_Task;
   --  Called by PendSV handler to switch current task.

   procedure Block_Until (Time_Stamp : A0B.Types.Unsigned_64);
   --  Blocks current task till given time.

   procedure System_Timer_Tick (Time_Stamp : A0B.Types.Unsigned_64);
   --  Called by the system timer.

end A0B.Tasking.Scheduler;