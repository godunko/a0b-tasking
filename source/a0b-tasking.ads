--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

private with System;
with System.Storage_Elements;

private with A0B.ARMv7M;
with A0B.Types;

package A0B.Tasking
  with Preelaborate
is

   use type A0B.Types.Unsigned_32;

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

   procedure Initialize
     (Master_Stack_Size   : System.Storage_Elements.Storage_Count;
      Use_Processor_Clock : Boolean;
      Clock_Frequency     : A0B.Types.Unsigned_32)
      with Pre =>
        Clock_Frequency mod 1_000_000 = 0
          and Clock_Frequency <= 2**20 * 1_000;
   --  Initialize tasking support. Given amount of bytes is reserved for use
   --  as master stack. Tasks stacks are allocated below this master stack.
   --
   --  @param Master_Stack_Size
   --  Size of the stack in bytes to reserve for master stack. This stack is
   --  used by the exception handlers.
   --  @param Use_Processor_Clock
   --  Source of the SysTick clock:
   --    * False - external clock
   --    * True  - processor clock
   --  @param Clock_Frequency
   --  Clock frequency of the SysTick timer (external or processor).

   procedure Run with No_Return;
   --  Run tasks. This subprogram never returns.
   --
   --  Note, this subprogram resets master stack to initial position, thus all
   --  data on the stack are lost.

   type Task_Subprogram is access procedure;

   type Task_Control_Block is limited private
     with Preelaborable_Initialization;

   procedure Register_Thread
     (Control_Block : aliased in out Task_Control_Block;
      Thread        : Task_Subprogram;
      Stack_Size    : System.Storage_Elements.Storage_Count);

   procedure Delay_Until (Time_Stamp : A0B.Types.Unsigned_64)
     with Inline_Always;

   type Suspension_Object is limited private
     with Preelaborable_Initialization;

   procedure Suspend_Until_True (SO : aliased in out Suspension_Object)
     with Inline_Always;

  --   procedure Suspend_Until_True_Or_Delay_Until
  --     (SO   : in out Suspension_Object;
  --      Till : A0B.Types.Unsigned_64);

private

   type Task_Control_Block_Access is
     access all Task_Control_Block with Storage_Size => 0;

   type Timer_Suspension_Object is record
      TCB  : System.Address;
      Till : A0B.Types.Unsigned_64;
      Next : System.Address;
   end record
     with Preelaborable_Initialization;

   type Timer_Suspension_Object_Access is
     access all Timer_Suspension_Object with Storage_Size => 0;

   type Task_State is (Idle, Runnable, Blocked);

   type Task_Control_Block is limited record
      Stack      : System.Address;
      State      : Task_State;
      Next       : System.Address;
      Timer      : aliased Timer_Suspension_Object;
      Suspension : System.Address;
   end record;
   --  State:
   --   - Idle     - special kind of task, run only there is no other tasks
   --   - Runnable - can be run
   --   - Waiting  - waiting for some event
   --
   --  Events: list of events task waiting for.
   --   - suspension object - to wait for signal from another task
   --   - wait for system's interrupt
   --   - wait for flag
   --   - timer event

   type Suspension_Object is limited record
      TCB   : System.Address;
      State : Boolean;
      --  Next  : System.Address;
   end record;

   type Suspension_Object_Access is access all Suspension_Object
     with Storage_Size => 0;

   Idle_Task_Control_Block : aliased Task_Control_Block;

   Current_Task : not null Task_Control_Block_Access :=
     Idle_Task_Control_Block'Access;
      --   with Linker_Section => ".dtcm.data";
   --  Task_List_Head : Task_Control_Block_Access;

   PendSV_Priority  : constant A0B.ARMv7M.Priority_Value := 255;
   SysTick_Priority : constant A0B.ARMv7M.Priority_Value := 255;
   SVCall_Priority  : constant A0B.ARMv7M.Priority_Value := 127;
   --  Priority values of PendSV, SysTick and SVCall exceptions.

   procedure Request_PendSV;
   --  Request Pend_SV exception.

end A0B.Tasking;