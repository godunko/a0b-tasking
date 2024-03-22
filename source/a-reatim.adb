--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking.System_Timer;

package body Ada.Real_Time is

   --  function "+" (Left : Time_Span; Right : Time) return Time;
   --  function "-" (Left : Time; Right : Time_Span) return Time;
   --  function "-" (Left : Time; Right : Time) return Time_Span;

   --  function "<" (Left, Right : Time) return Boolean;
   --  function "<="(Left, Right : Time) return Boolean;
   --  function ">" (Left, Right : Time) return Boolean;
   --  function ">="(Left, Right : Time) return Boolean;

   --  function "+" (Left, Right : Time_Span) return Time_Span;
   --  function "-" (Left, Right : Time_Span) return Time_Span;
   --  function "-" (Right : Time_Span) return Time_Span;
   --  function "*" (Left : Time_Span; Right : Integer) return Time_Span;
   --  function "*" (Left : Integer; Right : Time_Span) return Time_Span;
   --  function "/" (Left, Right : Time_Span) return Integer;
   --  function "/" (Left : Time_Span; Right : Integer) return Time_Span;

   --  function "abs"(Right : Time_Span) return Time_Span;

   --  function "<" (Left, Right : Time_Span) return Boolean;
   --  function "<="(Left, Right : Time_Span) return Boolean;
   --  function ">" (Left, Right : Time_Span) return Boolean;
   --  function ">="(Left, Right : Time_Span) return Boolean;

   --  function To_Duration (TS : Time_Span) return Duration;
   --  function To_Time_Span (D : Duration) return Time_Span;

   --  function Nanoseconds  (NS : Integer) return Time_Span;
   --  function Seconds      (S  : Integer) return Time_Span;
   --  function Minutes      (M  : Integer) return Time_Span;

   --  procedure Split(T : in Time; SC : out Seconds_Count;
   --  TS : out Time_Span);
   --  function Time_Of(SC : Seconds_Count; TS : Time_Span) return Time;

   ---------
   -- "+" --
   ---------

   function "+" (Left : Time; Right : Time_Span) return Time is
   begin
      return Left + Time (Right);
   end "+";

   -----------
   -- Clock --
   -----------

   function Clock return Time is
   begin
      return Ada.Real_Time.Time (A0B.Tasking.System_Timer.Clock);
   end Clock;

   --   ------------------
   --   -- Microseconds --
   --   ------------------

   --   function Microseconds (US : Integer) return Time_Span is
   --   begin
   --      return US * 1;
   --   end Microseconds;

   ------------------
   -- Milliseconds --
   ------------------

   function Milliseconds (MS : Integer) return Time_Span is
   begin
      return Time_Span (MS) * 1_000;
   end Milliseconds;

end Ada.Real_Time;
