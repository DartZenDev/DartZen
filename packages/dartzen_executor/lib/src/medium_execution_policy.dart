import 'package:meta/meta.dart';

/// Execution context and constraints for medium tasks.
///
/// Enforces deterministic, bounded execution:
/// - **timeout**: Maximum allowed duration for medium task execution.
/// - **failFast**: If true, exceeding timeout is a hard error (no retry).
@immutable
class MediumExecutionPolicy {
  /// Creates a medium execution policy with strict timeout enforcement.
  ///
  /// [timeout] defaults to 1 second. Exceeding it = execution failure.
  /// This ensures medium tasks do not hold Cloud Run instances longer
  /// than necessary.
  const MediumExecutionPolicy({this.timeout = const Duration(seconds: 1)});

  /// Maximum allowed execution time for a medium task.
  ///
  /// **Invariant**: If a task exceeds this duration, it is a bug in
  /// task classification, not a resource contention issue. The task
  /// should be reclassified as heavy.
  final Duration timeout;
}
