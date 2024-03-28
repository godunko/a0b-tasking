--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with System.Address_To_Access_Conversions;
with System.Machine_Code;
with System.Storage_Elements;         use System.Storage_Elements;

with A0B.ARMv7M.CMSIS;                use A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.System_Control_Block; use A0B.ARMv7M.System_Control_Block;
with A0B.ARMv7M.System_Timer;         use A0B.ARMv7M.System_Timer;
with A0B.Types.GCC_Builtins;

with A0B.Tasking.Context_Switching;
with A0B.Tasking.Interrupt_Handling;
with A0B.Tasking.Scheduler;
with A0B.Tasking.System_Timer;

package body A0B.Tasking is

   Next_Stack : System.Address;

   --  function To_Priority_Value
   --    (Item : Priority) return A0B.ARMv7M.Priority_Value is
   --      (A0B.ARMv7M.Priority_Value
   --        (Priority (A0B.ARMv7M.Priority_Value'Last) - Item));
   --  Conversion from abstract priority level to ARM priority value.

   estack : constant A0B.Types.Reserved_32
     with Import, Convention => C, External_Name => "_estack";

   procedure Idle_Thread;
   --  Thread that run idle loop.

   package Suspension_Condition_Conversions is
     new System.Address_To_Access_Conversions (Suspension_Condition);

   function To_Pointer
     (Item : System.Address) return Suspension_Condition_Access is
        (Suspension_Condition_Access
           (Suspension_Condition_Conversions.To_Pointer (Item)));

   function To_Address
     (Item : Suspension_Condition_Access) return System.Address is
        (Suspension_Condition_Conversions.To_Address
           (Suspension_Condition_Conversions.Object_Pointer (Item)));

   package TCB_Conversion is
     new System.Address_To_Access_Conversions (Task_Control_Block);

   function To_Address
     (Item : Task_Control_Block_Access) return System.Address is
        (TCB_Conversion.To_Address (TCB_Conversion.Object_Pointer (Item)));

   function To_Pointer
     (Item : System.Address) return Task_Control_Block_Access is
        (Task_Control_Block_Access (TCB_Conversion.To_Pointer (Item)));

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (Time_Stamp : A0B.Types.Unsigned_64) is
   begin
      Scheduler.Block_Until (Time_Stamp);

      --  Update task control block.

      --  Current_Task.Time  := Time_Stamp;

      --  Request PendVS exception. Do synchronization after modification of
      --  the register in the System Control Space to avoid side effects.

      SCB.ICSR := (PENDSVSET => True, others => <>);
      Data_Synchronization_Barrier;
      Instruction_Synchronization_Barrier;
   end Delay_Until;

   -------------
   -- Dequeue --
   -------------

   procedure Dequeue
     (Self : in out Suspension_Condition_List;
      Item : out Suspension_Condition_Access)
   is
      use type System.Address;

   begin
      if Self.Head = System.Null_Address then
         Item := null;

      else
         Item      := To_Pointer (Self.Head);
         Self.Head := Item.Next;
      end if;
   end Dequeue;

   ----------
   -- Head --
   ----------

   function Head
     (Self : Suspension_Condition_List) return Suspension_Condition_Access is
   begin
      return To_Pointer (Self.Head);
   end Head;

   -----------------
   -- Idle_Thread --
   -----------------

   procedure Idle_Thread is
   begin
      loop
         Wait_For_Interrupt;
      end loop;
   end Idle_Thread;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self       : in out Suspension_Condition;
      TCB        : not null Task_Control_Block_Access;
      Time_Stamp : A0B.Types.Unsigned_64) is
   begin
      Self.TCB  := To_Address (TCB);
      Self.Till := Time_Stamp;
      Self.Next := System.Null_Address;
   end Initialize;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Master_Stack_Size   : System.Storage_Elements.Storage_Count;
      Use_Processor_Clock : Boolean;
      Clock_Frequency     : A0B.Types.Unsigned_32)
   is
      Stack_Frame_Size : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Unsigned_32 (Context_Switching.Stack_Frame_Size);
      Power_Of_Two     : constant Integer :=
        32 - Integer (A0B.Types.GCC_Builtins.clz (Stack_Frame_Size));
      Stack_Size       : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Shift_Left (1, Power_Of_Two);

   begin
      Next_Stack := estack'Address - Master_Stack_Size;

      Idle_Task_Control_Block.Stack :=
        Context_Switching.Initialize_Stack (Idle_Thread'Access, Next_Stack);
      Idle_Task_Control_Block.State := Idle;
      --  Idle_Task_Control_Block.Time  := 0;
      Idle_Task_Control_Block.Next  := System.Null_Address;
      --    To_Address (Idle_Task_Control_Block'Access);

      Next_Stack :=
        @ - System.Storage_Elements.Storage_Offset (Stack_Size);

      System_Timer.Initialize_Timer (Use_Processor_Clock, Clock_Frequency);
   end Initialize;

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Self  : in out Suspension_Condition_List;
      After : Suspension_Condition_Access;
      Item  : not null Suspension_Condition_Access) is
   begin
      if After = null then
         Item.Next := Self.Head;
         Self.Head := To_Address (Item);

      else
         Item.Next  := After.Next;
         After.Next := To_Address (Item);
      end if;
   end Insert;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Self : Suspension_Condition_List) return Boolean is
      use type System.Address;

   begin
      return Self.Head = System.Null_Address;
   end Is_Empty;

   ----------
   -- Next --
   ----------

   function Next
     (Self : not null Suspension_Condition_Access)
      return Suspension_Condition_Access is
   begin
      return To_Pointer (Self.Next);
   end Next;

   ----------
   -- Next --
   ----------

   function Next
     (TCB : Task_Control_Block_Access) return Task_Control_Block_Access is
   begin
      return To_Pointer (TCB.Next);
   end Next;

   ---------------------
   -- Register_Thread --
   ---------------------

   procedure Register_Thread
     (Control_Block : aliased in out Task_Control_Block;
      Thread        : Task_Subprogram;
      Stack_Size    : System.Storage_Elements.Storage_Count)
   is
      use type System.Address;

      --  Last_Task : Task_Control_Block_Access := Idle_Task_Control_Block'Access;

   begin
      --  loop
      --     exit when Last_Task.Next
      --                 = To_Address (Idle_Task_Control_Block'Access);

      --     Last_Task := To_Pointer (Last_Task.Next);
      --  end loop;

      Control_Block.Stack :=
        Context_Switching.Initialize_Stack (Thread, Next_Stack);
      Control_Block.State := Runnable;
      --  Control_Block.Time  := 0;
      Control_Block.Next  := System.Null_Address;
      --  Control_Block.Next  := Last_Task.Next;

      --  Last_Task.Next := To_Address (Control_Block'Unchecked_Access);

      Next_Stack := @ - Stack_Size;

      Scheduler.Register_Task (Control_Block'Unchecked_Access);
   end Register_Thread;

   ---------
   -- Run --
   ---------

   procedure Run is
      use type A0B.Types.Unsigned_2;

      CPACR   : constant SCB_CPACR_Register := SCB.CPACR;
      Has_FPU : constant Boolean := (CPACR.CP10 /= 0) and (CPACR.CP11 /= 0);

   begin
      System_Timer.Enable_Timer;

      SCB.SHPR (A0B.ARMv7M.SVCall_Exception)  := SVCall_Priority;
      SCB.SHPR (A0B.ARMv7M.PendSV_Exception)  := PendSV_Priority;
      SCB.SHPR (A0B.ARMv7M.SysTick_Exception) := SysTick_Priority;
      --  Set priorities of system exceptions.

      if Has_FPU then
         declare
            CONTROL : CONTROL_Register := Get_CONTROL;

         begin
            CONTROL.FPCA := False;
            --  Clear FP execution bit, to use basic format of the exception
            --  frame. It is expected by SVC call to run the first task.

            Set_CONTROL (CONTROL);

            SCB_FP.FPCCR.LSPEN := True;
            --  Enable lazy save of the FPU context on interrupts.
         end;
      end if;

      --  Content of the master stack is not needed anymore, so reset MSP to
      --  the initial value. All preempted and pending interrupts should be
      --  completed first to be able to do this safely, so first reset
      --  priority boosting and enable all interrupts/faults.

      Set_BASEPRI (0);
      Instruction_Synchronization_Barrier;
      --  Reset priority boosting and ensure that priority is applied.

      Enable_Interrupts;
      Enable_Faults;
      --  Enable interrupts and faults.

      Set_MSP (estack'Address);
      --  Reset master stack to the initial value. It is safe do to here:
      --   - immidiately before the call of SVC to start first thread, so it
      --     will not be modified or older stored values are used by the
      --     current subprogram;
      --   - processor runs in Thread Mode without priority boosting, so
      --     there is no preempted exceptions at this point, thus nothing
      --     outside of this subprogram use this code.

      System.Machine_Code.Asm
        (Template => "svc 0",
         Volatile => True);
      --  Call SVC to start first thread. It never returns.

      raise Program_Error;
   end Run;

   ---------
   -- TCB --
   ---------

   function TCB
     (Self : Suspension_Condition_Access) return Task_Control_Block_Access is
   begin
      return To_Pointer (Self.TCB);
   end TCB;

end A0B.Tasking;
