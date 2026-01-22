import '../../dartzen_jobs.dart' show JobDescriptor;
import 'job_definition.dart' show JobDescriptor;

/// Context provided to a job handler during execution.
///
/// Contains metadata about the current execution attempt and any standard
/// payload data passed when the job was triggered.
class JobContext {
  /// The ID of the job being executed.
  ///
  /// This matches the `id` field of the associated [JobDescriptor].
  final String jobId;

  /// The timestamp when this specific execution attempt started.
  final DateTime executionTime;

  /// The current attempt number (1-based) for this execution.
  ///
  /// Use this to handle retry logic (e.g., ignore errors on first attempt,
  /// or apply manual backoff).
  final int attempt;

  /// Optional input data for the job handler.
  ///
  /// For `JobType.endpoint` jobs, this is the data passed to `ZenJobs.trigger`.
  final Map<String, dynamic>? payload;

  /// Creates a [JobContext].
  const JobContext({
    required this.jobId,
    required this.executionTime,
    required this.attempt,
    this.payload,
  });
}
