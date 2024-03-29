# Tasking

This crate provides simple capabilities to execute few "tasks" on the single core CPU.

It supports ARMv7-M CPUs only (Cortex-M3/M4/M7). It intended to be used with `light-cortex-m*` runtimes distributed with GNAT.

Each "task" is implemented by the procedure, which never returns.
Task can suspend its execution by `delay until` statement, or with `Suspend_Until_True` subprogram of the `Suspension_Object`.

Implementation of the `Ada.Real_Time` and `Ada.Synchronous_Task_Control` packages are provided for convenience and better portability.

## Examples

Few examples are available in the `examples` directory.
