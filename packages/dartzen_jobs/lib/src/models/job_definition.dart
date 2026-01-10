import 'job_context.dart';
import 'job_type.dart';

/// Function signature for job execution logic.
typedef JobHandler = Future<void> Function(JobContext context);

/// Definition of a job registered in the application code.
///
/// This class represents the immutable definition of a job, including its internal logic
/// ([handler]), architectural type ([type]), and default fallback configuration.
///
/// **Note**: Runtime configuration (like `enabled` status or modified intervals) is managed
/// via `JobConfig` in Firestore and overrides these defaults.
class JobDefinition {
  /// Unique identifier of the job.
  ///
  /// This ID must be unique across the entire application and is used for
  /// registration, triggering, and Firestore configuration lookups.
  final String id;

  /// The execution pattern for this job.
  final JobType type;

  /// The async function that executes the job logic.
  ///
  /// This function receives a [JobContext] containing metadata about the run.
  final JobHandler handler;

  /// Default cron schedule (for [JobType.scheduled] jobs).
  ///
  /// Used to populate Firestore configuration if no override exists.
  /// Example: '0 9 * * *' (Every day at 9 AM).
  final String? defaultCron;

  /// Default interval (for [JobType.periodic] jobs).
  ///
  /// Defines how often the job should run when using the `MasterJob` batching.
  final Duration? defaultInterval;

  /// Default execution priority.
  ///
  /// Higher values indicate higher priority.
  final int? defaultPriority;

  /// Default maximum number of retry attempts.
  final int? defaultMaxRetries;

  /// Creates a [JobDefinition].
  const JobDefinition({
    required this.id,
    required this.type,
    required this.handler,
    this.defaultCron,
    this.defaultInterval,
    this.defaultPriority,
    this.defaultMaxRetries,
  });
}
