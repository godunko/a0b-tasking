
pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking;

package P is

   On_Task  : aliased A0B.Tasking.Task_Control_Block;
   Off_Task : aliased A0B.Tasking.Task_Control_Block;

   procedure On;

   procedure Off;

end P;