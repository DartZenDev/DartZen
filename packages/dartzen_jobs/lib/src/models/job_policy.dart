/// Immutable job policy with explicit defaults.
///
/// `JobPolicy` captures execution-level defaults (retries, timeouts) that
/// can be attached to a `JobDescriptor`. Policies are immutable at runtime.
class JobPolicy {
  /// Maximum number of retries allowed for a job.
  final int maxRetries;

  /// Execution timeout for handlers.
  final Duration timeout;

  /// Create a [JobPolicy].
  const JobPolicy({
    this.maxRetries = 3,
    this.timeout = const Duration(minutes: 5),
  });

  /// A strict policy: no retries and short timeout.
  static const JobPolicy strict = JobPolicy(
    maxRetries: 0,
    timeout: Duration(minutes: 1),
  );
}
