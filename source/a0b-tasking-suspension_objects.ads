--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package A0B.Tasking.Suspension_Objects
  with Preelaborate
is

   procedure Set_True (SO : aliased in out Suspension_Object)
     with Inline_Always;

end A0B.Tasking.Suspension_Objects;
