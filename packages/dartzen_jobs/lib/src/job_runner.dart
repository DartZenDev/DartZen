import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import '../dartzen_jobs.dart';
import 'job_store.dart';
import 'job_validator.dart';

/// Represents a failure encountered during the execution of a job.
///
/// This error is returned when the job handler itself fails or when
/// pre-execution validation fails in a significant way.
class JobExecutionError extends ZenError {
  /// Creates a [JobExecutionError] with a descriptive message explaining the failure.
  const JobExecutionError(super.message);
}

/// Coordinator for single job execution and lifecycle management.
///
/// The [JobRunner] is responsible for the actual execution of a single job.
/// It wraps the core execution logic with common infrastructure concerns:
///
/// 1. **Validation**: Checks if the job is enabled, within its date range,
///    not explicitly skipped, and its dependencies are satisfied.
/// 2. **Telemetry**: Emits events for execution start, success, and failure.
/// 3. **State Updates**: Synchronizes [JobConfig] state (last run time, status, retries).
/// 4. **Logging**: Captures and logs errors with stack traces.
///
/// ## Execution Model Compliance
///
/// Job execution is **non-blocking** and **deterministic**:
/// - All I/O operations are async (Firestore, telemetry)
/// - Job handlers are responsible for their own execution safety
/// - State validation is fast, in-memory logic
/// - No hidden retries, concurrency, or background execution
///
/// If a job handler blocks the event loop, that is a defect in the
/// handler implementation, not in this runner.
class JobRunner {
  final JobStore _store;
  final Map<String, JobDescriptor> _registry;
  final TelemetryClient _telemetry;
  final Map<String, dynamic>? _zoneServices;

  /// Creates a [JobRunner] with a data store and telemetry client.
  ///
  /// [zoneServices] is an optional map of services to inject into the Zone
  /// during handler execution. This enables handlers to access runtime services
  /// without capturing them in the job payload. Common service keys:
  /// - `dartzen.executor`: true (marks executor context)
  /// - `dartzen.ai.service`: AIService instance
  /// - `dartzen.http.client`: HTTP client instance
  /// - `dartzen.logger`: Logger instance
  ///
  /// See docs/execution_model.md for the complete zone service contract.
  JobRunner(
    this._store,
    this._registry,
    this._telemetry, {
    Map<String, dynamic>? zoneServices,
  }) : _zoneServices = zoneServices;

  /// Executes a job by its unique identifier.
  ///
  /// This method performs validation against the job's current [JobConfig]
  /// before invoking the registered handler.
  ///
  /// ## Retry Semantics
  ///
  /// Retries are **automatic** and managed by the executor, not by the handler.
  /// The retry workflow is:
  ///
  /// 1. **First Execution**: `attempt = 1`, `currentRetries = 0`
  /// 2. **On Failure**: Increment `currentRetries` to match the attempt number
  /// 3. **On Next Execution**: Check if `currentRetries < policy.maxRetries`
  ///    - If yes: retry allowed, increment attempt counter
  ///    - If no: max retries exceeded, job fails permanently
  /// 4. **On Success**: Reset `currentRetries = 0`
  ///
  /// Example workflow for a job with `maxRetries = 3`:
  /// - Attempt 1: fails → currentRetries becomes 1
  /// - Attempt 2: fails → currentRetries becomes 2
  /// - Attempt 3: fails → currentRetries becomes 3
  /// - Attempt 4: fails but 3 >= maxRetries → job marked permanently failed
  ///
  /// **Handler Responsibility**: Handlers do not decide to retry. They throw
  /// on failure, and the executor handles retry logic. Handlers that require
  /// exponential backoff or custom retry logic must implement that internally.
  ///
  /// [jobId] must correspond to a registered [JobDescriptor].
  /// [payload] is optional input data for the job.
  /// [currentTime] allows deterministic execution for testing (defaults to now).
  Future<ZenResult<void>> execute(
    String jobId, {
    Map<String, dynamic>? payload,
    ZenTimestamp? currentTime,
  }) async {
    // Validate job descriptor exists (throws if not found)
    JobValidator.validateJobExists(jobId, _registry);

    final configResult = await _store.getJobConfig(jobId);
    if (configResult.isFailure) {
      return ZenResult.err(configResult.errorOrNull!);
    }

    final config = configResult.dataOrNull!;
    final now = currentTime?.value ?? DateTime.now().toUtc();

    // Check if job is enabled for execution
    final (isEligible, reason) = JobValidator.isEnabledForExecution(
      config,
      now,
    );
    if (!isEligible) {
      // Map reason to appropriate JobStatus
      final status = _mapSkipReasonToStatus(reason);
      await _store.updateJobState(jobId, lastStatus: status);
      return const ZenResult.ok(null);
    }

    // Validate all dependencies are satisfied
    for (final depId in config.dependencies) {
      final depResult = await _store.getJobConfig(depId);
      if (depResult.isFailure ||
          depResult.dataOrNull?.lastStatus != JobStatus.success) {
        await _store.updateJobState(
          jobId,
          lastStatus: JobStatus.skippedDependencyFailed,
        );
        return const ZenResult.ok(null);
      }
    }

    final attempt = config.currentRetries + 1;
    final context = JobContext(
      jobId: jobId,
      executionTime: now,
      attempt: attempt,
      payload: payload,
    );

    await _emit(jobId, 'start', timestamp: now, payload: {'attempt': attempt});

    try {
      final handler = HandlerRegistry.get(jobId);
      if (handler == null) {
        throw MissingDescriptorException(
          'No handler registered for job: $jobId',
        );
      }

      // Execute handler with optional Zone service injection
      await _executeHandlerInZone(handler, context);

      await _store.updateJobState(
        jobId,
        lastRun: now,
        lastStatus: JobStatus.success,
        currentRetries: 0,
      );
      await _emit(jobId, 'success', timestamp: now);
      return const ZenResult.ok(null);
    } catch (e, stack) {
      ZenLogger.instance.error(
        'Job $jobId failed',
        error: e,
        stackTrace: stack,
      );

      // Persist the attempt count as the new currentRetries counter.
      // On the next execution, if currentRetries >= policy.maxRetries, the job
      // will be marked as permanently failed and no further retries will occur.
      final nextRetries = attempt;
      await _store.updateJobState(
        jobId,
        lastRun: now,
        lastStatus: JobStatus.failure,
        currentRetries: nextRetries,
      );
      await _emit(
        jobId,
        'failure',
        timestamp: now,
        payload: {'error': e.toString(), 'retries': nextRetries},
      );

      return ZenResult.err(JobExecutionError('Job execution failed: $e'));
    }
  }

  Future<void> _emit(
    String jobId,
    String suffix, {
    required DateTime timestamp,
    Map<String, dynamic>? payload,
  }) => _telemetry.emitEvent(
    TelemetryEvent(
      name: 'job.execution.$suffix',
      timestamp: timestamp,
      scope: 'jobs',
      source: TelemetrySource.job,
      payload: {'job_id': jobId, if (payload != null) ...payload},
    ),
  );

  /// Maps a skip reason string to the appropriate [JobStatus].
  JobStatus _mapSkipReasonToStatus(String? reason) {
    if (reason == null) return JobStatus.success;
    if (reason.contains('disabled')) return JobStatus.skippedDisabled;
    if (reason.contains('not started')) return JobStatus.skippedNotStarted;
    if (reason.contains('ended')) return JobStatus.skippedEnded;
    if (reason.contains('skip date')) return JobStatus.skippedDateExclusion;
    return JobStatus.skippedDisabled; // Default fallback
  }

  /// Executes a handler with optional Zone service injection.
  ///
  /// If [_zoneServices] is provided, the handler runs inside a Zone with
  /// injected services accessible via `Zone.current[key]`. This allows
  /// handlers to access runtime dependencies (AI services, HTTP clients, etc.)
  /// without capturing them in the job payload.
  ///
  /// If no services are configured, the handler executes normally without
  /// Zone wrapping, ensuring backward compatibility with existing handlers.
  Future<void> _executeHandlerInZone(
    Future<void> Function(JobContext) handler,
    JobContext context,
  ) async {
    if (_zoneServices == null || _zoneServices.isEmpty) {
      // No zone services configured - execute handler directly
      await handler(context);
      return;
    }

    // Execute handler inside a Zone with injected services
    await runZoned(() => handler(context), zoneValues: _zoneServices);
  }
}
