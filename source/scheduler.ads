
pragma Restrictions (No_Elaboration_Code);

private with System;

with Interfaces; use Interfaces;

private with A0B.ARMv7M;

package Scheduler is

   type Priority is mod 2 ** 8;
   --  Task/interrupt of priority level. Zero means lowerest priority.
   --  Hardware may not support all priority levels.
   --
   --  To simplify code, priorities splitted into four ranges
   --   - zero-latency interrupts, highest priority range, can't call kernel's
   --     code
   --   - kernel priority, to protect kernel's data structures without
   --     disabling of interrupts
   --   - application priority, to be used by application's code (both tasks
   --     and interrupts)
   --   - scheduler's context switching, lowerest priority range, used for
   --     tasking context switch.

   subtype Application_Priority is Priority range 64 .. 127;

   procedure Initialize;

   procedure Run with No_Return;

   Clock : Unsigned_32 := 0 with Atomic, Volatile;

   type Thread_Subprogram is access procedure;

   procedure Register_Thread (Thread : Thread_Subprogram);

   procedure Delay_Until (Time_Stamp : Unsigned_32);

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

   PendSV_Priority  : constant A0B.ARMv7M.Priority_Value := 255;
   SysTick_Priority : constant A0B.ARMv7M.Priority_Value := 255;
   SVCall_Priority  : constant A0B.ARMv7M.Priority_Value := 127;
   --  Priority values of PendSV, SysTick and SVCall exceptions.

end Scheduler;