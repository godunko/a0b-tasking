
pragma Restrictions (No_Elaboration_Code);

with Interfaces; use Interfaces;

package Scheduler is

   pragma Elaborate_Body;

   procedure Initialize;

   procedure Run with No_Return;

   Clock : Unsigned_32 := 0 with Atomic, Volatile;

   type Thread_Subprogram is access procedure;

   procedure Register_Thread (Thread : Thread_Subprogram);

end Scheduler;