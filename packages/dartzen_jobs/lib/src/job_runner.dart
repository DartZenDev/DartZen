import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import '../dartzen_jobs.dart';
import 'job_store.dart';

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
class JobRunner {
  final JobStore _store;
  final Map<String, JobDefinition> _registry;
  final TelemetryClient _telemetry;

  /// Creates a [JobRunner] with a data store and telemetry client.
  JobRunner(this._store, this._registry, this._telemetry);

  /// Executes a job by its unique identifier.
  ///
  /// This method performs validation against the job's current [JobConfig]
  /// before invoking the registered handler.
  ///
  /// [jobId] must correspond to a registered [JobDefinition].
  /// [payload] is optional input data for the job.
  /// [currentTime] allows deterministic execution for testing (defaults to now).
  Future<ZenResult<void>> execute(
    String jobId, {
    Map<String, dynamic>? payload,
    ZenTimestamp? currentTime,
  }) async {
    final def = _registry[jobId];
    if (def == null) {
      ZenLogger.instance.error('Job definition not found for id: $jobId');
      return ZenResult.err(
        ZenNotFoundError('Job definition not found for id: $jobId'),
      );
    }

    final configResult = await _store.getJobConfig(jobId);
    if (configResult.isFailure) {
      return ZenResult.err(configResult.errorOrNull!);
    }

    final config = configResult.dataOrNull!;
    final now = currentTime?.value ?? DateTime.now().toUtc();

    if (!config.enabled) {
      await _store.updateJobState(jobId, lastStatus: JobStatus.skippedDisabled);
      return const ZenResult.ok(null);
    }

    if (config.startAt != null && now.isBefore(config.startAt!)) {
      await _store.updateJobState(
        jobId,
        lastStatus: JobStatus.skippedNotStarted,
      );
      return const ZenResult.ok(null);
    }
    if (config.endAt != null && now.isAfter(config.endAt!)) {
      await _store.updateJobState(jobId, lastStatus: JobStatus.skippedEnded);
      return const ZenResult.ok(null);
    }

    final today = DateTime(now.year, now.month, now.day);
    if (config.skipDates.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    )) {
      await _store.updateJobState(
        jobId,
        lastStatus: JobStatus.skippedDateExclusion,
      );
      return const ZenResult.ok(null);
    }

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
      await def.handler(context);

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
}
