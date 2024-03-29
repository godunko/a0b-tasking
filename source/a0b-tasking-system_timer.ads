--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package provides an interface to the SysTick timer

pragma Restrictions (No_Elaboration_Code);

with A0B.Types;

package A0B.Tasking.System_Timer
  with Preelaborate
is

   pragma Elaborate_Body;

   function Clock return A0B.Types.Unsigned_64;
   --   with Linker_Section => ".itcm.text";

   function Tick_Base return A0B.Types.Unsigned_64
     with Inline_Always;

   procedure Initialize_Timer
     (Use_Processor_Clock : Boolean;
      Clock_Frequency     : A0B.Types.Unsigned_32);
   --  Initialize SysTick timer

   procedure Enable_Timer;
   --  Enable SysTick timer and interrupt.

   procedure Overflow;
   --   with Linker_Section => ".itcm.text";
   --  Handle timer's overflow event.

end A0B.Tasking.System_Timer;