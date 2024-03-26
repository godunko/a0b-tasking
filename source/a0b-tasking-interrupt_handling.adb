--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.Tasking.Context_Switching;
with A0B.Tasking.Scheduler;
with A0B.Tasking.System_Timer;

package body A0B.Tasking.Interrupt_Handling is

   procedure PendSV_Handler
     with Export, Convention => C, External_Name => "PendSV_Handler",
          Linker_Section => ".itcm.text";

   procedure SVC_Handler
     with Export, Convention => C, External_Name => "SVC_Handler";

   procedure SysTick_Handler
     with Export, Convention => C, External_Name => "SysTick_Handler",
          Linker_Section => ".itcm.text";

   --------------------
   -- PendSV_Handler --
   --------------------

   procedure PendSV_Handler is
   begin
      Context_Switching.Save_Context;
      Set_BASEPRI (SVCall_Priority);
      Scheduler.Switch_Current_Task;
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

   ---------------------
   -- SysTick_Handler --
   ---------------------

   procedure SysTick_Handler is
   begin
      System_Timer.Overflow;
      Scheduler.System_Timer_Tick (System_Timer.Tick_Base);

      SCB.ICSR := (PENDSVSET => True, others => <>);
      --  Request PendSV exception to switch context
   end SysTick_Handler;

end A0B.Tasking.Interrupt_Handling;