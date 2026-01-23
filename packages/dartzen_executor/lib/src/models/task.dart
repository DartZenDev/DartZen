import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
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

/// Hard defaults applied when a descriptor has no arguments.
///
/// These defaults enforce a strict, explicit execution model:
/// - Tasks without explicit configuration default to lightweight.
/// - This prevents accidental heavy-weight behavior.
/// - Defaults are centralized and auditable.
class DefaultTaskDescriptors {
  DefaultTaskDescriptors._();

  /// Default weight when descriptor is empty.
  static const TaskWeight defaultWeight = TaskWeight.light;

  /// Default latency when descriptor is empty.
  static const Latency defaultLatency = Latency.fast;

  /// Default retryable flag when descriptor is empty.
  static const bool defaultRetryable = false;
}

/// Execution descriptor for a task.
///
/// Use this with the `descriptor` getter on your `ZenTask` subclass.
/// If constructed with no arguments, [DefaultTaskDescriptors] apply:
/// - weight: light
/// - latency: fast
/// - retryable: false
///
/// Semantics:
/// - `weight`: Determines executor routing (light/medium/heavy).
/// - `latency`: Documents expected duration; used for monitoring/telemetry.
/// - `retryable`: Indicates whether failures are safe to retry.
@immutable
class ZenTaskDescriptor {
  /// Creates a descriptor that declares a task's execution contract.
  ///
  /// **Empty descriptor** (`ZenTaskDescriptor()`) applies hard defaults.
  /// **Explicit arguments** override defaults individually.
  ///
  /// Parameters:
  /// - [weight]: Routing weight (defaults to [DefaultTaskDescriptors.defaultWeight]).
  /// - [latency]: Expected latency (defaults to [DefaultTaskDescriptors.defaultLatency]).
  /// - [retryable]: Retry safety (defaults to [DefaultTaskDescriptors.defaultRetryable]).
  const ZenTaskDescriptor({
    this.weight = DefaultTaskDescriptors.defaultWeight,
    this.latency = DefaultTaskDescriptors.defaultLatency,
    this.retryable = DefaultTaskDescriptors.defaultRetryable,
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
/// This class is **fully derived** from the task's [ZenTaskDescriptor]
/// and content. It is NOT authored by user code — all properties are
/// computed automatically.
///
/// Derived from:
/// - Descriptor getter: `weight`
/// - Task instance: `id` (auto-generated from task type and hash)
/// - Schema version: fixed at 1
///
/// Invariant: Weight comes ONLY from the `descriptor` getter. ID is
/// auto-generated from task content. Metadata cannot be lied about.
@immutable
class TaskMetadata {
  /// Internal constructor - do not use directly.
  @internal
  const TaskMetadata({
    required this.weight,
    required this.id,
    this.schemaVersion = 1,
  });

  /// Creates task metadata fully derived from task descriptor and content.
  ///
  /// This is the **only** way to create metadata. Everything is computed:
  /// - `weight` is provided from the descriptor
  /// - `id` is auto-generated from task type and payload hash
  /// - `schemaVersion` is always 1
  ///
  /// Usage:
  /// ```dart
  /// class MyTask extends ZenTask<int> {
  ///   @override
  ///   ZenTaskDescriptor get descriptor =>
  ///       const ZenTaskDescriptor(weight: TaskWeight.medium);
  ///
  ///   @override
  ///   Future<int> execute() async => 42;
  /// }
  /// ```
  ///
  /// The `metadata` property is automatically implemented by the base class
  /// to call this builder with the task's descriptor.
  static TaskMetadata fromDescriptor<T>({
    required ZenTask<T> task,
    required ZenTaskDescriptor descriptor,
  }) {
    // Generate deterministic ID from task type and payload
    final taskType = task.runtimeType.toString();
    final payload = task.toPayload();
    // Deterministic, canonical hash based on JSON with sorted keys
    final canonical = _canonicalJson(payload);
    final digest = sha256.convert(utf8.encode(canonical)).toString();
    final autoId = '${taskType}_$digest';

    return TaskMetadata(
      weight: descriptor.weight,
      id: autoId,
      // schemaVersion: 1 is default,
    );
  }

  /// The computational weight of the task (from [ZenTaskDescriptor]).
  final TaskWeight weight;

  /// Auto-generated unique identifier for this task instance.
  ///
  /// Generated from task type name and payload content hash.
  /// Deterministic - same task with same payload produces same id.
  final String id;

  /// The schema version for job envelope evolution (current version is 1).
  final int schemaVersion;

  /// Converts this metadata to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight.name,
    'schemaVersion': schemaVersion,
  };
}

// Produces a canonical JSON string by sorting map keys recursively.
// This ensures stable hashing across VM runs and platforms.
String _canonicalJson(Map<String, dynamic> map) {
  dynamic canonicalize(dynamic value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      final out = <String, dynamic>{};
      for (final key in sortedKeys) {
        out[key] = canonicalize(value[key]);
      }
      return out;
    } else if (value is List) {
      return value.map(canonicalize).toList();
    } else {
      return value;
    }
  }

  final canonical = canonicalize(map) as Map<String, dynamic>;
  return jsonEncode(canonical);
}

/// Abstract base class for all executable tasks.
///
/// Subclasses must provide:
/// - [descriptor]: Getter that returns the execution descriptor (REQUIRED).
/// - [execute]: The task's business logic (REQUIRED).
/// - [toPayload]: Serializable task data (optional, defaults to empty map).
///
/// Example (explicit descriptor):
/// ```dart
/// class ComputePrimeTask extends ZenTask<int> {
///   ComputePrimeTask(this.n);
///   final int n;
///
///   @override
///   ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
///     weight: TaskWeight.medium,
///     latency: Latency.slow,
///     retryable: true,
///   );
///
///   @override
///   Future<int> execute() async => _computeNthPrime(n);
/// }
/// ```
///
/// Example (default descriptor):
/// ```dart
/// class SimpleTask extends ZenTask<String> {
///   @override
///   ZenTaskDescriptor get descriptor => const ZenTaskDescriptor();
///
///   @override
///   Future<String> execute() async => 'done';
/// }
/// ```
///
/// Key Principles:
/// - `descriptor` getter is the ONLY source of truth for execution cost.
/// - `metadata` is automatically computed by base class (never override).
abstract class ZenTask<T> {
  /// The task's execution descriptor (sole source of truth).
  ///
  /// Provide a `const ZenTaskDescriptor(...)` that declares how the task
  /// should be routed. If constructed with no arguments, hard defaults apply.
  ZenTaskDescriptor get descriptor;

  /// The metadata describing this task (auto-computed from descriptor).
  ///
  /// Automatically derived from [descriptor] and task content.
  /// Marked `@nonVirtual` to prevent overriding in subclasses.
  @nonVirtual
  TaskMetadata get metadata =>
      TaskMetadata.fromDescriptor(task: this, descriptor: descriptor);

  /// Executes the task's business logic and returns the result.
  ///
  /// For light and medium tasks, this method is invoked directly by the executor.
  /// For heavy tasks, this method is serialized and dispatched to the jobs system.
  @protected
  Future<T> execute();

  /// Optional runtime guard check. Override to enforce executor-only context.
  ///
  /// By default, this is a no-op. Tasks that require strict isolation
  /// (e.g., AI tasks with service injection) can override to validate Zone.
  @protected
  void validateExecutorContext() {
    // No-op by default; tasks can override if needed
  }

  /// Entry point used by `ZenExecutor` to invoke a task deterministically.
  ///
  /// This preserves the protected intent of [execute] for application code
  /// while giving the executor a stable hook. Application code should not
  /// call this directly; use `ZenExecutor.execute(...)` instead.
  ///
  /// **Runtime Guard**: Tasks can optionally validate executor context via
  /// [validateExecutorContext]. The executor sets Zone marker `#dartzenExecutor`.
  @internal
  Future<T> invokeInternal() {
    validateExecutorContext();
    return execute();
  }

  /// Converts the task's payload to a JSON-serializable map.
  ///
  /// Used for heavy tasks that must be serialized for job dispatch.
  /// Subclasses handling heavy tasks should override this method.
  Map<String, dynamic> toPayload() => {};
}
