/// Represents the exhaustive list of execution outcomes for a job.
enum JobStatus {
  /// The job handler completed successfully.
  success,

  /// The job handler failed or an exception was thrown during execution.
  failure,

  /// Execution was skipped because the job is disabled in configuration.
  skippedDisabled,

  /// Execution was skipped because the current time is before the start date.
  skippedNotStarted,

  /// Execution was skipped because the current time is after the end date.
  skippedEnded,

  /// Execution was skipped because the current date is explicitly excluded.
  skippedDateExclusion,

  /// Execution was skipped because one or more dependencies have not succeeded.
  skippedDependencyFailed;

  /// Returns the storage-compatible string representation of the status.
  String toStorageString() {
    switch (this) {
      case JobStatus.success:
        return 'success';
      case JobStatus.failure:
        return 'failure';
      case JobStatus.skippedDisabled:
        return 'skipped_disabled';
      case JobStatus.skippedNotStarted:
        return 'skipped_not_started';
      case JobStatus.skippedEnded:
        return 'skipped_ended';
      case JobStatus.skippedDateExclusion:
        return 'skipped_date_exclusion';
      case JobStatus.skippedDependencyFailed:
        return 'skipped_dependency_failed';
    }
  }

  /// Parses a storage-compatible string into a [JobStatus].
  ///
  /// Returns null if the status string is unrecognized.
  static JobStatus? fromStorageString(String? status) {
    if (status == null) return null;
    for (final value in JobStatus.values) {
      if (value.toStorageString() == status) return value;
    }
    return null;
  }
}
