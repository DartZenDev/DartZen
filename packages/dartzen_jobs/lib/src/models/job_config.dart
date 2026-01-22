import 'job_definition.dart';
import 'job_status.dart';

/// Configuration state of a job, typically stored in Firestore.
///
/// This class represents the runtime state and configuration that controls
/// whether and how a job is executed. This data is pulled from the `jobs` collection.
///
/// Separating configuration ([JobConfig]) from definition ([JobDescriptor]) allows
/// developers to change job parameters (disable a job, change its interval, update a cron)
/// instantly via the database without redeploying the application code.
class JobConfig {
  /// Unique identifier of the job.
  ///
  /// Must match the associated [JobDescriptor.id].
  final String id;

  /// Whether execution is enabled.
  ///
  /// If false, the job will not run even if triggered or scheduled.
  final bool enabled;

  /// Earliest datetime to run the job (inclusive).
  ///
  /// Useful for "launching" a feature or job at a future date.
  final DateTime? startAt;

  /// Latest datetime to run the job (inclusive).
  ///
  /// Useful for temporary jobs that should sunset after a specific date.
  final DateTime? endAt;

  /// Specific dates to skip execution.
  ///
  /// Useful for handling holidays or scheduled maintenance windows.
  final List<DateTime> skipDates;

  /// IDs of other jobs that must successfully complete before this one.
  ///
  /// This creates a dependency graph. This job will only run if the
  /// dependencies have successfully completed their latest run.
  final List<String> dependencies;

  /// Priority level (higher runs first).
  ///
  /// Used to prioritize critical tasks during execution or queueing.
  final int priority;

  /// Maximum retry attempts.
  ///
  /// Defines how many times a failed execution should be retried.
  final int maxRetries;

  /// Interval for periodic execution.
  ///
  /// Used exclusively for periodic jobs to determine recurrence frequency.
  final Duration? interval;

  /// Cron expression for scheduled execution.
  ///
  /// Primarily used for reference or for synchronization with external schedulers.
  final String? cron;

  /// Timestamp of the last successful or attempted run.
  ///
  /// This state field is crucial for determining if periodic jobs are "due".
  final DateTime? lastRun;

  /// Expected timestamp of the next run.
  ///
  /// Calculated for periodic jobs to optimize batch discovery.
  final DateTime? nextRun;

  /// Final outcome of the last execution attempt.
  final JobStatus? lastStatus;

  /// Current number of retries for the last failed execution.
  ///
  /// Reset to 0 upon successful execution.
  final int currentRetries;

  /// Optional grouping for administration and filtering.
  final String? group;

  /// Creates a [JobConfig].
  const JobConfig({
    required this.id,
    required this.enabled,
    this.startAt,
    this.endAt,
    this.skipDates = const [],
    this.dependencies = const [],
    this.priority = 0,
    this.maxRetries = 3,
    this.interval,
    this.cron,
    this.lastRun,
    this.nextRun,
    this.lastStatus,
    this.currentRetries = 0,
    this.group,
  });
}
