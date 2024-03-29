--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking.Suspension_Objects;

package body Ada.Synchronous_Task_Control is

   -------------------
   -- Current_State --
   -------------------

   function Current_State (S : Suspension_Object) return Boolean is
   begin
      raise Program_Error;
      return False;
   end Current_State;

   --------------
   -- Set_True --
   --------------

   procedure Set_True (S : in out Suspension_Object) is
   begin
      A0B.Tasking.Suspension_Objects.Set_True (S.SO);
   end Set_True;

   ---------------
   -- Set_False --
   ---------------

   procedure Set_False (S : in out Suspension_Object) is
   begin
      raise Program_Error;
   end Set_False;

   ------------------------
   -- Suspend_Until_True --
   ------------------------

   procedure Suspend_Until_True (S : in out Suspension_Object) is
   begin
      A0B.Tasking.Suspend_Until_True (S.SO);
   end Suspend_Until_True;

end Ada.Synchronous_Task_Control;
