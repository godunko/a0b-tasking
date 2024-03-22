
pragma Restrictions (No_Elaboration_Code);

private with A0B.Types;
--  pragma Style_Checks (Off, A0B.Types);

package Ada.Real_Time is

   type Time is private;
   Time_First : constant Time;
   Time_Last  : constant Time;
   --   Time_Unit : constant := 0.001;

   type Time_Span is private;
   --   Time_Span_First : constant Time_Span;
   --   Time_Span_Last : constant Time_Span;
   --   Time_Span_Zero : constant Time_Span;
   --   Time_Span_Unit : constant Time_Span;

   --   Tick : constant Time_Span;
   function Clock return Time with Inline_Always;

   function "+" (Left : Time; Right : Time_Span) return Time
     with Inline_Always;
   --   function "+" (Left : Time_Span; Right : Time) return Time;
   --   function "-" (Left : Time; Right : Time_Span) return Time;
   --   function "-" (Left : Time; Right : Time) return Time_Span;

   --   function "<" (Left, Right : Time) return Boolean;
   --   function "<="(Left, Right : Time) return Boolean;
   --   function ">" (Left, Right : Time) return Boolean;
   --   function ">="(Left, Right : Time) return Boolean;

   --   function "+" (Left, Right : Time_Span) return Time_Span;
   --   function "-" (Left, Right : Time_Span) return Time_Span;
   --   function "-" (Right : Time_Span) return Time_Span;
   --   function "*" (Left : Time_Span; Right : Integer) return Time_Span;
   --   function "*" (Left : Integer; Right : Time_Span) return Time_Span;
   --   function "/" (Left, Right : Time_Span) return Integer;
   --   function "/" (Left : Time_Span; Right : Integer) return Time_Span;

   --   function "abs"(Right : Time_Span) return Time_Span;

   --   function "<" (Left, Right : Time_Span) return Boolean;
   --   function "<="(Left, Right : Time_Span) return Boolean;
   --   function ">" (Left, Right : Time_Span) return Boolean;
   --   function ">="(Left, Right : Time_Span) return Boolean;

   --   function To_Duration (TS : Time_Span) return Duration;
   --   function To_Time_Span (D : Duration) return Time_Span;

   --   function Nanoseconds  (NS : Integer) return Time_Span;
   --   function Microseconds (US : Integer) return Time_Span;
   function Milliseconds (MS : Integer) return Time_Span
     with Inline_Always;
   --   function Seconds      (S  : Integer) return Time_Span;
   --   function Minutes      (M  : Integer) return Time_Span;

   --   type Seconds_Count is range 0 .. 59;

   --   procedure Split(T : in Time; SC : out Seconds_Count;
   --   TS : out Time_Span);
   --   function Time_Of(SC : Seconds_Count; TS : Time_Span) return Time;

private
   --  Not specified by the language

   type Time is new A0B.Types.Unsigned_64;

   Time_First : constant Time := Time'First;
   Time_Last  : constant Time := Time'Last;

   type Time_Span is new A0B.Types.Unsigned_64;
   --   Time_Span_First : constant Time_Span := (others => <>);
   --   Time_Span_Last : constant Time_Span := (others => <>);
   --   Time_Span_Zero : constant Time_Span := (others => <>);
   --   Time_Span_Unit : constant Time_Span := (others => <>);

   --   Tick : constant Time_Span := (others => <>);
end Ada.Real_Time;
