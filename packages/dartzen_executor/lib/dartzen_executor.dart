/// Explicit task execution runtime for DartZen.
///
/// This package provides a deterministic, ownership-driven execution model
/// for tasks of varying computational weight:
///
/// - **Light tasks**: Execute inline, non-blocking, in the event loop.
/// - **Medium tasks**: Execute in a local isolate for bounded CPU work.
/// - **Heavy tasks**: Dispatch to the jobs system with explicit cloud routing.
///
/// **Single Public Entry Point**:
/// ```dart
/// final result = await executor.execute(task);
/// ```
///
/// All execution decisions are made internally by ZenExecutor based on
/// the task's ZenTaskDescriptor. Users do not select execution strategies,
/// dispatch jobs directly, or spawn isolates manually.
///
/// Core principles:
/// - **Explicit over implicit**: `queueId` and `serviceUrl` are required at construction.
/// - **Deterministic routing**: Task weight determines execution path; no hidden magic.
/// - **Ownership model**: Destination configuration is fixed at executor creation;
///   per-call overrides are explicit and optional.
/// - **Fixed schema**: Job payloads use a versioned envelope `{taskType, metadata, payload}`.
/// - **Descriptor-only**: Every task MUST implement a `descriptor` getter.
/// - **Strict access control**: Only `execute()` is public; all routing is internal.
///
/// Example:
/// ```dart
/// class ComputeTask extends ZenTask<int> {
///   @override
///   ZenTaskDescriptor get descriptor =>
///       const ZenTaskDescriptor(weight: TaskWeight.medium);
///
///   @override
///   protected Future<int> execute() async => 42;
/// }
///
/// final executor = ZenExecutor(
///   config: ZenExecutorConfig(
///     queueId: 'my-task-queue',
///     serviceUrl: 'https://my-service.run.app',
///   ),
///   dispatcher: const CloudJobDispatcher(),
/// );
///
/// final result = await executor.execute(ComputeTask());
/// ```
library;

export 'src/executor_config.dart';
export 'src/l10n/executor_messages.dart';
export 'src/medium_execution_policy.dart';
export 'src/models/execution_overrides.dart';
export 'src/models/heavy_dispatch_result.dart';
export 'src/models/job_envelope.dart';
export 'src/models/task.dart';
export 'src/models/task_rehydration.dart';
export 'src/zen_executor.dart';
