import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import 'job_store.dart';
import 'models/job_context.dart';

/// Represents a failure encountered during the orchestration of periodic jobs.
class MasterJobProcessingError extends ZenError {
  /// Creates a [MasterJobProcessingError] with a descriptive message explaining the failure.
  const MasterJobProcessingError(super.message);
}

/// Specialized coordinator that orchestrates the execution of periodic jobs.
///
/// The [MasterJob] is designed to optimize costs in serverless environments.
/// Instead of scheduling every periodic job individually, a single external
/// scheduler triggers this "Master Job" (e.g., every minute).
///
/// When [run], this coordinator:
/// 1. Fetches all enabled periodic jobs from [JobStore].
/// 2. Calculates which jobs are "due" based on their `interval` and `lastRun`.
/// 3. Executes the due jobs sequentially via the provided `_executeJob` callback.
///
/// ## Execution Model Compliance
///
/// Master job orchestration is **non-blocking**:
/// - Job fetching is async I/O (Firestore)
/// - Date calculations are fast, deterministic logic
/// - Job execution is delegated to the provided callback
/// - Sequential execution prevents job fan-out and cost explosion
///
/// The master job itself does not perform CPU-intensive work.
/// It only coordinates when other jobs should run.
class MasterJob {
  final JobStore _store;
  final TelemetryClient _telemetry;
  final Future<ZenResult<void>> Function(
    String jobId, {
    Map<String, dynamic>? payload,
    ZenTimestamp? currentTime,
  })
  _executeJob;

  /// Creates a [MasterJob] coordinator.
  ///
  /// [_executeJob] is usually a reference to `JobRunner.execute`.
  MasterJob(this._store, this._telemetry, this._executeJob);

  /// Executes the master job logic to discover and trigger due periodic jobs.
  ///
  /// [context] provides metadata about the master job itself, including its
  /// current [JobContext.executionTime] which is used as the reference "now"
  /// for determining due jobs.
  Future<ZenResult<void>> run(JobContext context) async {
    final jobsResult = await _store.getEnabledPeriodicJobs();
    if (jobsResult.isFailure) {
      return ZenResult.err(jobsResult.errorOrNull!);
    }

    final jobs = jobsResult.dataOrNull!;
    final now = context.executionTime;
    final timestamp = ZenTimestamp.from(now);

    for (final job in jobs) {
      try {
        if (job.interval == null) {
          continue;
        }

        final effectiveLastRun =
            job.lastRun ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final due = effectiveLastRun.add(job.interval!);

        if (due.isBefore(now) || due.isAtSameMomentAs(now)) {
          final result = await _executeJob(job.id, currentTime: timestamp);

          if (result.isSuccess) {
            await _telemetry.emitEvent(
              TelemetryEvent(
                name: 'job.master.trigger',
                timestamp: now,
                scope: 'jobs',
                source: TelemetrySource.server,
                payload: {'triggered_job': job.id},
              ),
            );
          }
        }
      } catch (e, stack) {
        ZenLogger.instance.error(
          'Error processing periodic job ${job.id}',
          error: e,
          stackTrace: stack,
        );
      }
    }

    return const ZenResult.ok(null);
  }
}
