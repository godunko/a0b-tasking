
pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M.CMSIS; use A0B.ARMv7M.CMSIS;

with Scheduler.Context_Switching;

package body Scheduler.Interrupt_Handling is

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
      Reschedule;
      Context_Switching.Restore_Context;
   end PendSV_Handler;

   -----------------
   -- SVC_Handler --
   -----------------

   procedure SVC_Handler is
   begin
      --  Start first task.

      Set_MSP (estack'Address);
      --  Reset master stack to the initial value.

      Context_Switching.Restore_Context;
   end SVC_Handler;

end Scheduler.Interrupt_Handling;