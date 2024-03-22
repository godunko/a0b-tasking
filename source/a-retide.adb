--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking;

package body Ada.Real_Time.Delays is

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (T : Time) is
   begin
      A0B.Tasking.Delay_Until (A0B.Types.Unsigned_64 (T));
   end Delay_Until;

end Ada.Real_Time.Delays;
