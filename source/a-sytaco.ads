
pragma Restrictions (No_Elaboration_Code);

private with A0B.Tasking;

package Ada.Synchronous_Task_Control
  with Preelaborate
--   Nonblocking, Global => in out synchronized
is

   type Suspension_Object is limited private
     with Preelaborable_Initialization;

   procedure Set_True (S : in out Suspension_Object)
     with Inline_Always;

   procedure Set_False (S : in out Suspension_Object)
     with Inline_Always;

   function Current_State (S : Suspension_Object) return Boolean
     with Inline_Always;

   procedure Suspend_Until_True (S : in out Suspension_Object)
   --   with Nonblocking => False;
     with Inline_Always;

private

   type Suspension_Object is limited record
      SO : aliased A0B.Tasking.Suspension_Object;
   end record;

end Ada.Synchronous_Task_Control;
