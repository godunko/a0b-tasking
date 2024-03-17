--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with Ada.Unchecked_Conversion;

with System.Storage_Elements; use System.Storage_Elements;
with System.Machine_Code;

with A0B.ARMv7M.CMSIS;        use A0B.ARMv7M.CMSIS;
with A0B.Types;               use A0B.Types;

package body A0B.Tasking.Context_Switching is

   NL : constant Character := ASCII.LF;
   --  New line sequence for Asm templates.

   --  ARMv7-M use two kinds of stack frame for exception handler: basic and
   --  extended. Last one is used when at least one FPU operation has been
   --  executed by the thread.
   --
   --  CPU stores only some registers when entering exception handler. Unsaved
   --  registers need to be saved for the context switching. Likewise, we use
   --  two kinds of additional stack frame to store unsaved registers.
   --
   --  Below is format of the used stack frame.
   --
   --          Basic       Extended
   --                   25   Reserved
   --                   24   FPSCR
   --                   23   S15
   --                   22   S14
   --                   21   S13
   --                   20   S12
   --                   19   S11
   --                   18   S10
   --                   17   S9
   --                   16   S8
   --                   15   S7
   --                   14   S6
   --                   13   S5
   --                   12   S4
   --                   11   S3
   --                   10   S2
   --                    9   S1
   --                    8   S0
   --       7   xPSR     7   xPSR
   --       6   PC       6   PC
   --       5   LR       5   LR
   --       4   R12      4   R12
   --       3   R3       3   R3
   --       2   R2       2   R2
   --       1   R1       1   R1
   --       0   R0       0   R0
   --  >>> PSP register on enter into/before leave of exception handler <<<
   --
   --                   24   S31
   --                   23   S30
   --                   22   S29
   --                   21   S28
   --                   20   S27
   --                   19   S26
   --                   18   S25
   --                   17   S24
   --                   16   S23
   --                   15   S22
   --                   14   S21
   --                   13   S20
   --                   12   S19
   --                   11   S18
   --                   10   S17
   --                    9   S16
   --       8   LR       8   LR
   --       7   R11      7   R11
   --       6   R10      6   R10
   --       5   R9       5   R9
   --       4   R8       4   R8
   --       3   R7       3   R7
   --       2   R6       2   R6
   --       1   R5       1   R5
   --       0   R4       0   R4
   --  >>> SP register stored in the task control block <<<

   subtype Stack_Element is A0B.Types.Unsigned_32;
   --  Unit of the stack.

   EH_Basic_Frame_Length : constant := 8;
   CS_Basic_Frame_Length : constant := 9;
   --  Length in stack elements of the exception handler and context switching
   --  stack frames.

   EH_Basic_Frame_Size : constant :=
     EH_Basic_Frame_Length * Stack_Element'Max_Size_In_Storage_Elements;
   CS_Basic_Frame_Size : constant :=
     CS_Basic_Frame_Length * Stack_Element'Max_Size_In_Storage_Elements;
   --  Size in storage elements of the exception handler and context switching
   --  stack frames.

   EH_LR_Index   : constant := 5;
   EH_PS_Index   : constant := 6;
   EH_xPSR_Index : constant := 7;
   CS_LR_Index   : constant := 8;
   --  Indices of the particular registers in the stack frames.

   INITIAL_EXC_RETURN : constant := 16#FFFF_FFFD#;
   --  Exception return value for the Link Register to run thread code for
   --  the first time. It means that processor will returns to Thread Mode,
   --  to use Process Stack Pointer, without restore of the FPU context.

   INITIAL_xPSR_VALUE : constant := 16#0100_0000#;
   --  Initial value of the xPSR register for starting thread. It means that
   --  Thumb instructions mode is enabled.

   LOCKUP_THREAD_RETURN : constant := 16#FFFF_FFFF#;
   --  Return value for the Link Register to switch processor into lockup
   --  state when thread subprogram returns.

   ----------------------
   -- Initialize_Stack --
   ----------------------

   function Initialize_Stack
     (Thread : Thread_Subprogram;
      Stack  : System.Address) return System.Address
   is
      type Unsigned_32_Array is
        array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_32;

      function To_Unsigned_32 is
        new Ada.Unchecked_Conversion
              (Thread_Subprogram, A0B.Types.Unsigned_32);

      EH_Frame : Unsigned_32_Array (0 .. EH_Basic_Frame_Length - 1)
        with Address => Stack - EH_Basic_Frame_Size;
      CS_Frame : Unsigned_32_Array (0 .. CS_Basic_Frame_Length - 1)
        with Address => Stack - EH_Basic_Frame_Size - CS_Basic_Frame_Size;

   begin
      --  Clear stack memory

      EH_Frame := (others => 0);
      CS_Frame := (others => 0);

      --  Initialize exception handler stack frame to start execution of the
      --  task code after context switch, and to lockup CPU if subprogram
      --  returns.

      EH_Frame (EH_LR_Index)   := LOCKUP_THREAD_RETURN;
      EH_Frame (EH_PS_Index)   := To_Unsigned_32 (Thread);
      EH_Frame (EH_xPSR_Index) := INITIAL_xPSR_VALUE;

      --  Initialize context switching stack frame to start execution of the
      --  task code.

      CS_Frame (CS_LR_Index) := INITIAL_EXC_RETURN;

      return CS_Frame'Address;
   end Initialize_Stack;

   ---------------------
   -- Restore_Context --
   ---------------------

   procedure Restore_Context is separate;

   ------------------
   -- Save_Context --
   ------------------

   procedure Save_Context is separate;

end A0B.Tasking.Context_Switching;