import '../../dartzen_jobs.dart' show HandlerRegistry;
import '../handler_registry.dart' show HandlerRegistry;
import 'job_context.dart';
import 'job_policy.dart';
import 'job_type.dart';

/// Function signature for job execution logic. Kept for compatibility.
typedef JobHandler = Future<void> Function(JobContext context);

/// Metadata-only descriptor for a job.
///
/// This class is deliberately free of executable logic. Handlers must be
/// registered separately via [HandlerRegistry]. Descriptors declare identity
/// and policy metadata only.
class JobDescriptor {
  /// [id] is the unique identifier for the job.
  final String id;

  /// [type] specifies the job type (one-off, recurring, etc).
  final JobType type;

  /// [defaultCron] is the default cron expression for scheduling (if applicable).
  final String? defaultCron;

  /// [defaultInterval] is the default interval duration for scheduling (if applicable).
  final Duration? defaultInterval;

  /// [defaultPriority] is the default priority for the job.
  final int? defaultPriority;

  /// [defaultMaxRetries] is the default maximum number of retries for the job.
  final int? defaultMaxRetries;

  /// [policy] defines the job's execution policy.
  final JobPolicy policy;

  /// Creates a new [JobDescriptor].
  const JobDescriptor({
    required this.id,
    required this.type,
    this.defaultCron,
    this.defaultInterval,
    this.defaultPriority,
    this.defaultMaxRetries,
    this.policy = const JobPolicy(),
  });
}
