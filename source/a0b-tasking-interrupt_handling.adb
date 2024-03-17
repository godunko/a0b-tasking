--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M.CMSIS; use A0B.ARMv7M.CMSIS;

with A0B.Tasking.Context_Switching;

package body A0B.Tasking.Interrupt_Handling is

   procedure PendSV_Handler
     with Export, Convention => C, External_Name => "PendSV_Handler";

   procedure SVC_Handler
     with Export, Convention => C, External_Name => "SVC_Handler";

   --------------------
   -- PendSV_Handler --
   --------------------

   procedure PendSV_Handler is
   begin
      Context_Switching.Save_Context;
      Set_BASEPRI (SVCall_Priority);
      Reschedule;
      Set_BASEPRI (0);
      Context_Switching.Restore_Context;
   end PendSV_Handler;

   -----------------
   -- SVC_Handler --
   -----------------

   procedure SVC_Handler is
   begin
      --  Start first task.

      Context_Switching.Restore_Context;
   end SVC_Handler;

end A0B.Tasking.Interrupt_Handling;