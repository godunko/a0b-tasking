--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking.Scheduler;

package body A0B.Tasking.Suspension_Objects is

   --------------
   -- Set_True --
   --------------

   procedure Set_True (SO : aliased in out Suspension_Object) is
   begin
      Scheduler.Set_True (SO);
   end Set_True;

end A0B.Tasking.Suspension_Objects;
