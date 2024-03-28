--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with System.Address_To_Access_Conversions;

with A0B.ARMv7M.CMSIS; use A0B.ARMv7M.CMSIS;
with A0B.Tasking.System_Timer;

package body A0B.Tasking.Scheduler is

   Runnable_Tasks : Task_Control_Block_List;
   --  Blocked_Tasks  : Task_Control_Block_List;
   Waiting        : Suspension_Condition_List;

   package Runnable_Queue is

      use type System.Address;

      procedure Enqueue (TCB : not null Task_Control_Block_Access)
        with Pre => TCB.State = Runnable and TCB.Next = System.Null_Address;
      --  Enqueue given task to the end of the queue.

      procedure Dequeue (TCB : out Task_Control_Block_Access);
      --  Dequeue first task in the queue.

   end Runnable_Queue;

   -----------------
   -- Block_Until --
   -----------------

   procedure Block_Until (Time_Stamp : A0B.Types.Unsigned_64) is
      use type A0B.Types.Unsigned_64;

      Previous : Suspension_Condition_Access := null;
      Item     : Suspension_Condition_Access;

   begin
      Set_BASEPRI (SVCall_Priority);

      Current_Task.State := Blocked;

      Initialize (Current_Task.Timer, Current_Task, Time_Stamp);

      Item := Head (Waiting);

      loop
         exit when Item = null;
         exit when Item.Till > Time_Stamp;

         Previous := Item;
         Item     := Next (Item);
      end loop;

      Insert (Waiting, After => Previous, Item => Current_Task.Timer'Access);

      Set_BASEPRI (0);
   end Block_Until;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task (TCB : not null Task_Control_Block_Access) is
   --     Previous : Task_Control_Block_Access := Head (Runnable_Tasks);

   begin
      Runnable_Queue.Enqueue (TCB);
   --     if Previous = null then
   --        Insert (Runnable_Tasks, After => null, Item => TCB);

   --     else
   --        loop
   --           exit when Next (Previous) = null;

   --           Previous := Next (Previous);
   --        end loop;

   --        Insert (Runnable_Tasks, After => Previous, Item => TCB);
   --     end if;
   end Register_Task;

   --------------------
   -- Runnable_Queue --
   --------------------

   package body Runnable_Queue is

      package TCB_Conversion is
        new System.Address_To_Access_Conversions (Task_Control_Block);

      function To_Address
        (Item : Task_Control_Block_Access) return System.Address is
           (TCB_Conversion.To_Address (TCB_Conversion.Object_Pointer (Item)));

      function To_Pointer
        (Item : System.Address) return Task_Control_Block_Access is
           (Task_Control_Block_Access (TCB_Conversion.To_Pointer (Item)));

      Head : Task_Control_Block_Access;
      Tail : Task_Control_Block_Access;

      -------------
      -- Dequeue --
      -------------

      procedure Dequeue (TCB : out Task_Control_Block_Access) is
      begin
         if Head = null then
            TCB := null;

         else
            TCB  := Head;
            Head := To_Pointer (TCB.Next);
            Tail := (if Head /= null then Tail else null);

            TCB.Next := System.Null_Address;
         end if;
      end Dequeue;

      -------------
      -- Enqueue --
      -------------

      procedure Enqueue (TCB : not null Task_Control_Block_Access) is
         Last : Task_Control_Block_Access := Head;

      begin
         if Head = null then
            Head := TCB;
            Tail := TCB;

         else
            declare
               pragma Suppress (Access_Check);
            begin
               Tail.Next := To_Address (TCB);
               Tail      := TCB;
            end;
         end if;
         --  if Self.Head = System.Null_Address then
         --     Self.Head := To_Address (Item);
         --     Item.Next := System.Null_Address;

         --  else
         --     loop
         --        exit when Last.Next = System.Null_Address;

         --        Last := To_Pointer (Last.Next);
         --     end loop;

         --     Last.Next := To_Address (Item);
         --     Item.Next := System.Null_Address;
         --  end if;
      end Enqueue;

   end Runnable_Queue;

   -------------------------
   -- Switch_Current_Task --
   -------------------------

   procedure Switch_Current_Task is
      use type A0B.Types.Unsigned_64;

      pragma Suppress (All_Checks);

      --  Clock     : constant A0B.Types.Unsigned_64 := System_Timer.Clock;
      --  Next_Task : Task_Control_Block_Access      := Current_Task;

      Item : Task_Control_Block_Access;

   begin
      --  loop
      --     Next_Task := Next (Next_Task);

      --     exit when Next_Task = Current_Task;

      --     if Next_Task.State /= Idle then
      --        if Next_Task.Time /= 0 and then Next_Task.Time <= Clock then
      --           Next_Task.State := Runnable;
      --           Next_Task.Time  := 0;
      --        end if;

      --        exit when Next_Task.State = Runnable;
      --     end if;
      --  end loop;

      --  if Next_Task.State /= Runnable then
      --     Current_Task := Idle_Task_Control_Block'Access;
      --     --  Run idle task

      --  else
      --     Current_Task := Next_Task;
      --  end if;

      Runnable_Queue.Dequeue (Item);

      if Current_Task.State = Runnable then
         Runnable_Queue.Enqueue (Item);
      end if;

      if Item = null then
         Current_Task := Idle_Task_Control_Block'Access;

      else
         Current_Task := Item;
      end if;
   end Switch_Current_Task;

   -----------------------
   -- System_Timer_Tick --
   -----------------------

   procedure System_Timer_Tick (Time_Stamp : A0B.Types.Unsigned_64) is
      use type A0B.Types.Unsigned_64;

      Item : Suspension_Condition_Access;

   begin
      loop
         Item := Head (Waiting);

         exit when Item = null;
         exit when Item.Till > Time_Stamp;

         Dequeue (Waiting, Item);
         TCB (Item).all.State := Runnable;
         Runnable_Queue.Enqueue (TCB (Item));
         --  if Item.Till <= Time_Stamp then
         --     null;
         --  end if;

         --  Item := Next (Item);
      end loop;
   end System_Timer_Tick;

end A0B.Tasking.Scheduler;