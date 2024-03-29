--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Real_Time;
with Ada.Synchronous_Task_Control;

with A0B.Tasking;

package body LED_Blink is

   use type Ada.Real_Time.Time;

   procedure Last_Chance_Handler is null
     with Export, Convention => C, Link_Name => "__gnat_last_chance_handler";

   On_Task    : aliased A0B.Tasking.Task_Control_Block;
   Off_Task   : aliased A0B.Tasking.Task_Control_Block;
   Blink_Task : aliased A0B.Tasking.Task_Control_Block;

   LED_On  : Ada.Synchronous_Task_Control.Suspension_Object;
   LED_Off : Ada.Synchronous_Task_Control.Suspension_Object;

   package Platform is
      procedure Configure with Inline_Always;
      procedure On with Inline_Always;
      procedure Off with Inline_Always;
   end Platform;

   procedure On;
   procedure Off;
   procedure Blink;

   -----------
   -- Blink --
   -----------

   procedure Blink is
      Interval : constant Ada.Real_Time.Time_Span :=
        Ada.Real_Time.Milliseconds (1_000);
      C        : Ada.Real_Time.Time := Ada.Real_Time.Clock;

   begin
      loop
         Ada.Synchronous_Task_Control.Set_True (LED_On);

         C := @ + Interval;
         delay until C;

         Ada.Synchronous_Task_Control.Set_True (LED_Off);

         C := @ + Interval;
         delay until C;
      end loop;
   end Blink;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Platform.Configure;

      A0B.Tasking.Register_Thread (On_Task, On'Access, 16#100#);
      A0B.Tasking.Register_Thread (Off_Task, Off'Access, 16#100#);
      A0B.Tasking.Register_Thread (Blink_Task, Blink'Access, 16#100#);
   end Initialize;

   ---------
   -- Off --
   ---------

   procedure Off is
   begin
      loop
         Ada.Synchronous_Task_Control.Suspend_Until_True (LED_Off);
         Platform.Off;
      end loop;
   end Off;

   --------
   -- On --
   --------

   procedure On is
   begin
      loop
         Ada.Synchronous_Task_Control.Suspend_Until_True (LED_On);
         Platform.On;
      end loop;
   end On;

   --------------
   -- Platform --
   --------------

   package body Platform is separate;

end LED_Blink;