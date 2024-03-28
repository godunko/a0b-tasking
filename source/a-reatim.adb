--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Tasking.System_Timer;

package body Ada.Real_Time is

   use type A0B.Types.Unsigned_64;

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

   --  procedure Split(T : in Time; SC : out Seconds_Count;
   --  TS : out Time_Span);
   --  function Time_Of(SC : Seconds_Count; TS : Time_Span) return Time;

   Nanosecond_Units  : constant := 1;
   Microsecond_Units : constant := Nanosecond_Units * 1_000;
   Millisecond_Units : constant := Microsecond_Units * 1_000;
   Second_Units      : constant := Millisecond_Units * 1_000;
   Minute_Units      : constant := Second_Units * 60;

   ---------
   -- "+" --
   ---------

   function "+" (Left : Time; Right : Time_Span) return Time is
   begin
      return
        Time (A0B.Types.Unsigned_64 (Left) + A0B.Types.Unsigned_64 (Right));
   end "+";

   ---------
   -- "+" --
   ---------

   function "+" (Left : Time_Span; Right : Time) return Time is
   begin
      return
        Time (A0B.Types.Unsigned_64 (Left) + A0B.Types.Unsigned_64 (Right));
   end "+";

   ---------
   -- "-" --
   ---------

   function "-" (Left : Time; Right : Time_Span) return Time is
   begin
      return
        Time (A0B.Types.Unsigned_64 (Left) - A0B.Types.Unsigned_64 (Right));
   end "-";

   ---------
   -- "-" --
   ---------

   function "-" (Left : Time; Right : Time) return Time_Span is
   begin
      return
        Time_Span
          (A0B.Types.Unsigned_64 (Left) - A0B.Types.Unsigned_64 (Right));
   end "-";

   -----------
   -- Clock --
   -----------

   function Clock return Time is
   begin
      return Ada.Real_Time.Time (A0B.Tasking.System_Timer.Clock);
   end Clock;

   ------------------
   -- Microseconds --
   ------------------

   function Microseconds (US : Integer) return Time_Span is
   begin
      return Time_Span (A0B.Types.Unsigned_64 (US) * Microsecond_Units);
   end Microseconds;

   ------------------
   -- Milliseconds --
   ------------------

   function Milliseconds (MS : Integer) return Time_Span is
   begin
      return Time_Span (A0B.Types.Unsigned_64 (MS) * Millisecond_Units);
   end Milliseconds;

   -------------
   -- Minutes --
   -------------

   function Minutes (M : Integer) return Time_Span is
   begin
      return Time_Span (A0B.Types.Unsigned_64 (M) * Minute_Units);
   end Minutes;

   -----------------
   -- Nanoseconds --
   -----------------

   function Nanoseconds (NS : Integer) return Time_Span is
   begin
      return Time_Span (A0B.Types.Unsigned_64 (NS) * Nanosecond_Units);
   end Nanoseconds;

   -------------
   -- Seconds --
   -------------

   function Seconds (S : Integer) return Time_Span is
   begin
      return Time_Span (A0B.Types.Unsigned_64 (S) * Second_Units);
   end Seconds;

end Ada.Real_Time;
