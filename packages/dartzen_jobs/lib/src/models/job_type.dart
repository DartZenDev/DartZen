import '../master_job.dart' show MasterJob;

/// The architectural pattern used to execute a job.
///
/// DartZen Jobs supports three distinct patterns, each tailored for different
/// serverless workloads and cost profiles.
enum JobType {
  /// Event-driven job triggered programmatically.
  ///
  /// Typically invoked via `ZenJobs.trigger()`. Creates a task in Google Cloud Tasks
  /// which invokes the service asynchronously. Best for high-volume or long-running
  /// tasks where immediate user feedback is not required.
  endpoint,

  /// Cron-scheduled job triggered by an external scheduler.
  ///
  /// Typically triggered by Google Cloud Scheduler on a fixed time pattern.
  /// Best for deterministic tasks like "Daily Report at 9 AM" or "Midnight Cleanup".
  scheduled,

  /// Interval-based job managed by the internal [MasterJob] batching system.
  ///
  /// Designed to optimize serverless costs. Instead of multiple external triggers,
  /// a single scheduler invokes the [MasterJob] periodically (e.g., every minute),
  /// which then executes all due periodic jobs in a single sequential batch.
  periodic,
}
