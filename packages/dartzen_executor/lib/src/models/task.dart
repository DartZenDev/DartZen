import 'package:meta/meta.dart';

/// The computational weight classification for a task.
///
/// Determines the execution strategy:
/// - [light]: Inline async execution in the event loop.
/// - [medium]: Local isolate execution for bounded CPU work.
/// - [heavy]: Cloud job dispatch via the jobs system.
enum TaskWeight {
  /// Lightweight, non-blocking task executed inline in the event loop.
  light,

  /// CPU-bound task executed in a local isolate for isolation.
  medium,

  /// Long-running or resource-intensive task dispatched to cloud jobs.
  heavy,
}

/// Expected latency classification for a task.
enum Latency {
  /// Fast tasks (tens of milliseconds)
  fast,

  /// Medium latency tasks (hundreds of milliseconds to ~1s)
  medium,

  /// Slow tasks (multi-second) that may still route to medium/heavy
  slow,
}

/// Declarative execution contract for a task.
@immutable
class ZenTaskDescriptor {
  /// Creates a descriptor that declares a task's execution contract.
  ///
  /// [weight] determines routing by the executor (light/medium/heavy).
  /// [latency] communicates expected duration for documentation/telemetry.
  /// [retryable] indicates whether callers or the jobs system may retry.
  const ZenTaskDescriptor({
    required this.weight,
    required this.latency,
    this.retryable = true,
  });

  /// Routing weight (light/medium/heavy).
  final TaskWeight weight;

  /// Expected latency classification.
  final Latency latency;

  /// Indicates whether the task is retryable by the caller or jobs system.
  final bool retryable;
}

/// Metadata describing the execution characteristics of a task.
///
/// Used by the executor to determine routing and logging context.
@immutable
class TaskMetadata {
  /// Creates task metadata with the specified weight and identifier.
  ///
  /// [id] must be deterministic and unique within the task's context.
  /// [schemaVersion] defaults to 1 and is used only by downstream consumers;
  /// the executor does not interpret this field.
  const TaskMetadata({
    required this.weight,
    required this.id,
    this.schemaVersion = 1,
  });

  /// The computational weight of the task.
  final TaskWeight weight;

  /// A deterministic, unique identifier for this task instance.
  final String id;

  /// The schema version for job envelope evolution.
  ///
  /// Defaults to 1. This field is used only by downstream consumers and is not
  /// interpreted by the executor itself.
  final int schemaVersion;

  /// Converts this metadata to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight.name,
    'schemaVersion': schemaVersion,
  };
}

/// Abstract base class for all executable tasks.
///
/// Subclasses must provide:
/// - [metadata]: Execution characteristics and routing information.
/// - [execute]: The task's business logic.
///
/// Example:
/// ```dart
/// class ComputePrimeTask extends ZenTask<int> {
///   ComputePrimeTask(this.n);
///
///   final int n;
///
///   @override
///   TaskMetadata get metadata => TaskMetadata(
///     weight: TaskWeight.medium,
///     id: 'compute_prime_$n',
///   );
///
///   @override
///   Future<int> execute() async => _computeNthPrime(n);
/// }
/// ```
abstract class ZenTask<T> {
  /// The metadata describing this task's execution requirements.
  TaskMetadata get metadata;

  /// Executes the task's business logic and returns the result.
  ///
  /// For light and medium tasks, this method is invoked directly by the executor.
  /// For heavy tasks, this method is serialized and dispatched to the jobs system.
  @protected
  Future<T> execute();

  /// Entry point used by `ZenExecutor` to invoke a task deterministically.
  ///
  /// This preserves the protected intent of [execute] for application code
  /// while giving the executor a stable hook. Application code should not
  /// call this directly; use `ZenExecutor.execute(...)` instead.
  @internal
  Future<T> invokeInternal() => execute();

  /// Converts the task's payload to a JSON-serializable map.
  ///
  /// Used for heavy tasks that must be serialized for job dispatch.
  /// Subclasses handling heavy tasks should override this method.
  Map<String, dynamic> toPayload() => {};
}
