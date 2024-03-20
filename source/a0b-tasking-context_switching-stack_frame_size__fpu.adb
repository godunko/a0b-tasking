--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This is version for ARMv7-M CPU with FPU extension

separate (A0B.Tasking.Context_Switching)
function Stack_Frame_Size return System.Storage_Elements.Storage_Count is
begin
   return 204;
end Stack_Frame_Size;