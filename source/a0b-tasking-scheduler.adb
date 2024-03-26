--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking.System_Timer;

package body A0B.Tasking.Scheduler is

   -------------------------
   -- Switch_Current_Task --
   -------------------------

   procedure Switch_Current_Task is
      use type A0B.Types.Unsigned_64;

      pragma Suppress (All_Checks);

      Clock     : constant A0B.Types.Unsigned_64 := System_Timer.Clock;
      Next_Task : Task_Control_Block_Access      := Current_Task;

   begin
      loop
         Next_Task := Next (Next_Task);

         exit when Next_Task = Current_Task;

         if Next_Task.State /= Idle then
            if Next_Task.Time /= 0 and then Next_Task.Time <= Clock then
               Next_Task.State := Runnable;
               Next_Task.Time  := 0;
            end if;

            exit when Next_Task.State = Runnable;
         end if;
      end loop;

      if Next_Task.State /= Runnable then
         Current_Task := Idle_Task_Control_Block'Access;
         --  Run idle task

      else
         Current_Task := Next_Task;
      end if;
   end Switch_Current_Task;

end A0B.Tasking.Scheduler;