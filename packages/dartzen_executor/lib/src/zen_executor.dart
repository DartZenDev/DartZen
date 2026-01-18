import 'dart:async';
import 'dart:isolate';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

import 'executor_config.dart';
import 'job_dispatcher.dart';
import 'l10n/executor_messages.dart';
import 'medium_execution_policy.dart';
import 'models/execution_overrides.dart';
import 'models/heavy_dispatch_result.dart';
import 'models/job_envelope.dart';
import 'models/task.dart';

/// Executor runtime for task dispatch with strict routing enforcement.
///
/// **Execution Model Compliance**:
/// - **Pure router**: Routes to light/medium/heavy paths; does NOT manage job lifecycle.
/// - **Non-blocking**: Light tasks execute inline without blocking the event loop.
/// - **Isolated CPU work**: Medium tasks run in a local isolate with enforced timeout.
/// - **Cloud dispatch**: Heavy tasks route through injected dispatcher with explicit config.
///
/// **Ownership Model**:
/// - Constructor requires `queueId` and `serviceUrl` for heavy task destination.
/// - Per-call overrides are explicit and optional via [ExecutionOverrides].
/// - No implicit fallbacks, env lookups, or magic defaults.
///
/// **Strict Annotation Enforcement**:
/// - Task weight is an **execution invariant**, not advisory.
/// - If marked `heavy`, the task **must** go to jobs; no fallback.
/// - If task exceeds medium timeout, execution fails; no retry.
///
/// **Schema Enforcement**:
/// - Heavy tasks produce a fixed, validated job envelope.
/// - Payload schema is a mandatory contract.
class ZenExecutor {
  /// Creates an executor with explicit configuration for heavy task routing.
  ///
  /// **Required Parameters**:
  /// - [config]: Specifies the default destination for heavy tasks.
  /// - [dispatcher]: Injects job dispatch implementation (no implicit lookups).
  /// - [mediumPolicy]: Enforces timeout bounds for medium task execution.
  ///
  /// **Optional Parameters**:
  /// - [localization]: Provides localized error messages (defaults to English).
  ZenExecutor({
    required this.config,
    required this.dispatcher,
    this.mediumPolicy = const MediumExecutionPolicy(),
    ZenLocalizationService? localization,
    String language = 'en',
  }) : _messages = ExecutorMessages(
         localization ??
             ZenLocalizationService(
               config: const ZenLocalizationConfig(isProduction: false),
             ),
         language,
       );

  /// The default configuration for heavy task dispatch.
  final ZenExecutorConfig config;

  /// The job dispatcher (injected dependency; no implicit lookups).
  final JobDispatcher dispatcher;

  /// The execution policy for medium tasks (enforces timeout bounds).
  final MediumExecutionPolicy mediumPolicy;

  final ExecutorMessages _messages;

  /// Executes a task according to its weight classification with strict enforcement.
  ///
  /// **Descriptor Requirement**:
  /// - Every [ZenTask] must implement a `descriptor` getter.
  /// - Missing `descriptor` ⇒ compile-time error (abstract member not implemented).
  /// - Empty descriptor ⇒ hard defaults applied ([DefaultTaskDescriptors]).
  ///
  /// **Routing** (execution invariant):
  /// - [TaskWeight.light]: Inline async execution in event loop.
  /// - [TaskWeight.medium]: Local isolate execution with enforced timeout.
  /// - [TaskWeight.heavy]: Cloud job dispatch via injected dispatcher.
  ///
  /// **Weight Enforcement**: If a task is marked with a weight, it **must** follow
  /// that path. No fallback if timeout exceeded or resource constraints hit.
  ///
  /// **Override Policy**:
  /// - [overrides] allows explicit per-call destination override for heavy tasks only.
  /// - If [overrides] is null, uses constructor-provided [config] values.
  /// - No implicit defaults or fallbacks.
  ///
  /// **Timeout Policy for Medium**:
  /// - Execution that exceeds `mediumPolicy.timeout` is a **hard failure**.
  /// - Exceeding timeout indicates task misclassification, not transient issue.
  /// - No automatic retry or fallback to heavy execution.
  ///
  /// Returns [ZenResult<T>] with either the task result or an error.
  Future<ZenResult<T>> execute<T>(
    ZenTask<T> task, {
    ExecutionOverrides? overrides,
  }) async {
    final metadata = task.metadata;

    ZenLogger.instance.info(
      'Executing task: ${metadata.id}',
      internalData: {
        'weight': metadata.weight.name,
        'taskType': task.runtimeType.toString(),
      },
    );

    try {
      switch (metadata.weight) {
        case TaskWeight.light:
          return await _executeLight(task);

        case TaskWeight.medium:
          return await _executeMedium(task);

        case TaskWeight.heavy:
          // Heavy tasks return HeavyDispatchResult, which is a separate type
          // Cast is safe because we control both sides of the contract
          return (await _executeHeavy(task, overrides)) as ZenResult<T>;
      }
    } catch (e, stackTrace) {
      ZenLogger.instance.error(
        'Task execution failed: ${metadata.id}',
        error: e,
        stackTrace: stackTrace,
        internalData: {
          'weight': metadata.weight.name,
          'taskType': task.runtimeType.toString(),
        },
      );
      return ZenResult.err(
        ZenUnknownError(
          _messages.taskExecutionFailed(task.runtimeType.toString()),
          internalData: {'taskId': metadata.id},
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Executes a light task inline in the event loop.
  ///
  /// **Non-Blocking Guarantee**: Uses async/await without CPU-bound work.
  Future<ZenResult<T>> _executeLight<T>(ZenTask<T> task) async {
    ZenLogger.instance.debug(
      'Executing light task inline: ${task.metadata.id}',
    );

    final result = await task.invokeInternal();
    return ZenResult.ok(result);
  }

  /// Executes a medium task in a local isolate with enforced timeout.
  ///
  /// **Timeout Enforcement**:
  /// - Execution that exceeds `mediumPolicy.timeout` is a **hard failure**.
  /// - Failure does NOT trigger retry or fallback to heavy execution.
  /// - Timeout indicates task misclassification, not transient resource issue.
  ///
  /// **Isolation Guarantee**: Uses `Isolate.run()` to isolate CPU-bound work
  /// from the main event loop. Suitable for short-lived, bounded computations.
  ///
  /// **Async Execution Model**: Task execution must complete within the isolate.
  /// The isolate awaits the Future internally to enforce the isolation boundary.
  Future<ZenResult<T>> _executeMedium<T>(ZenTask<T> task) async {
    ZenLogger.instance.debug(
      'Executing medium task in isolate (timeout: ${mediumPolicy.timeout}): '
      '${task.metadata.id}',
    );

    try {
      final result =
          await Isolate.run<T>(() async => await task.invokeInternal()).timeout(
            mediumPolicy.timeout,
            onTimeout: () {
              throw TimeoutException(
                'Medium task exceeded timeout ${mediumPolicy.timeout}',
                mediumPolicy.timeout,
              );
            },
          );
      return ZenResult.ok(result);
    } on TimeoutException catch (e, st) {
      ZenLogger.instance.error(
        'Medium task timeout (misclassification): ${task.metadata.id}',
        error: e,
        stackTrace: st,
        internalData: {
          'taskId': task.metadata.id,
          'timeout': mediumPolicy.timeout.toString(),
        },
      );
      return ZenResult.err(
        ZenUnknownError(
          _messages.mediumTaskTimeout,
          internalData: {
            'taskId': task.metadata.id,
            'timeout': mediumPolicy.timeout.toString(),
          },
          stackTrace: st,
        ),
      );
    }
  }

  /// Dispatches a heavy task to the jobs system via injected dispatcher.
  ///
  /// **Routing Invariant**:
  /// - Heavy tasks **must** be dispatched; no fallback to medium or inline.
  /// - Dispatch failure is a hard error (not retry-able at this level).
  ///
  /// **Configuration**:
  /// - Uses constructor-provided [config] by default.
  /// - Applies explicit [overrides] if provided (no implicit fallbacks).
  /// - Validates envelope schema before dispatch.
  ///
  /// **Dispatcher Responsibility**:
  /// - The injected [dispatcher] handles all job system communication.
  /// - Executor does NOT manage jobs lifecycle or polling.
  /// - Dispatch return = queuing complete, not execution guarantee.
  ///
  /// **Schema Enforcement**:
  /// Produces a fixed job envelope:
  /// ```json
  /// {
  ///   "taskType": "TaskClassName",
  ///   "metadata": { "id": "...", "weight": "heavy", "schemaVersion": 1 },
  ///   "payload": { ... }
  /// }
  /// ```
  ///
  /// Returns immediately after successful dispatch (does not wait for job completion).
  Future<ZenResult<HeavyDispatchResult>> _executeHeavy<T>(
    ZenTask<T> task,
    ExecutionOverrides? overrides,
  ) async {
    final envelope = JobEnvelope.fromTask(task);

    // Validate envelope schema (MUST be enforced)
    final validationResult = envelope.validate();
    if (validationResult.isFailure) {
      return ZenResult.err(validationResult.errorOrNull!);
    }

    // Determine destination: explicit override or constructor config
    final queueId = overrides?.queueId ?? config.queueId;
    final serviceUrl = overrides?.serviceUrl ?? config.serviceUrl;

    ZenLogger.instance.info(
      'Dispatching heavy task via injected dispatcher: ${task.metadata.id}',
      internalData: {
        'queueId': queueId,
        'serviceUrl': serviceUrl,
        'taskType': envelope.taskType,
      },
    );

    // Dispatch via injected dispatcher (strict DI, no implicit environment)
    try {
      final dispatchResult = await dispatcher.dispatch(
        jobId: task.metadata.id,
        queueId: queueId,
        serviceUrl: serviceUrl,
        payload: envelope.toJson(),
      );

      return dispatchResult.fold(
        (_) {
          ZenLogger.instance.info(
            'Heavy task dispatched successfully: ${task.metadata.id}',
            internalData: {'queueId': queueId, 'serviceUrl': serviceUrl},
          );
          // Return success with HeavyDispatchResult descriptor
          // Actual task result is unavailable at dispatch time (async)
          return ZenResult.ok(
            HeavyDispatchResult.dispatched(taskId: task.metadata.id),
          );
        },
        (error) {
          ZenLogger.instance.error(
            'Failed to dispatch heavy task: ${task.metadata.id}',
            error: error,
            internalData: {'taskType': envelope.taskType, 'queueId': queueId},
          );
          return ZenResult.err(error);
        },
      );
    } catch (e, stackTrace) {
      ZenLogger.instance.error(
        'Unexpected error dispatching heavy task: ${task.metadata.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return ZenResult.err(
        ZenUnknownError(
          _messages.taskExecutionFailed(task.runtimeType.toString()),
          internalData: {'taskId': task.metadata.id},
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
