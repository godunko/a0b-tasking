
pragma Restrictions (No_Elaboration_Code);

private with System;

with Interfaces; use Interfaces;

package Scheduler is

   --  pragma Elaborate_Body;

   procedure Initialize;

   procedure Run with No_Return;

   Clock : Unsigned_32 := 0 with Atomic, Volatile;

   type Thread_Subprogram is access procedure;

   procedure Register_Thread (Thread : Thread_Subprogram);

private

   type Task_Control_Block is record
      Stack  : System.Address;
      Id     : Integer;
      --  Stack  : System.Address := System.Null_Address;
      --  Unused : Boolean := True;
   end record;

   type Task_Control_Block_Access is access all Task_Control_Block;

   procedure Reschedule;

   Task_Table   : array (0 .. 3) of aliased Task_Control_Block;
   Current_Task : not null Task_Control_Block_Access :=
     Task_Table (Task_Table'First)'Unchecked_Access with Volatile;

   estack     : constant Interfaces.Unsigned_64
     with Import, Convention => C, External_Name => "_estack";

end Scheduler;