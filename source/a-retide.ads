--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This is implementation unit for the GNAT compiler (FSF GCC 13).

pragma Restrictions (No_Elaboration_Code);

package Ada.Real_Time.Delays is

   procedure Delay_Until (T : Time) with Inline_Always;

end Ada.Real_Time.Delays;
