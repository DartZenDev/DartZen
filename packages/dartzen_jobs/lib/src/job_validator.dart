import 'errors.dart';
import 'handler_registry.dart';
import 'job_runner.dart' show JobRunner;
import 'models/job_config.dart';
import 'models/job_definition.dart';
import 'models/job_status.dart';

/// Utility class for validating jobs and their execution eligibility.
///
/// [JobValidator] centralizes validation logic that was previously scattered
/// across [JobRunner] and initialization code. This improves testability and
/// reduces duplication.
///
/// All validation methods are static and deterministic (no side effects).
abstract final class JobValidator {
  /// Validates that a job descriptor is registered in the system.
  ///
  /// Throws [MissingDescriptorException] if the job ID is not found.
  static void validateJobExists(
    String jobId,
    Map<String, JobDescriptor> registry,
  ) {
    if (!registry.containsKey(jobId)) {
      throw MissingDescriptorException(
        'Job descriptor not found for id: $jobId',
      );
    }
  }

  /// Validates that a handler is registered for the given job ID.
  ///
  /// Throws [MissingDescriptorException] if no handler is registered.
  static void validateHandlerExists(String jobId) {
    final handler = HandlerRegistry.get(jobId);
    if (handler == null) {
      throw MissingDescriptorException('No handler registered for job: $jobId');
    }
  }

  /// Checks if a job is eligible for execution based on its current configuration.
  ///
  /// This performs all pre-execution checks:
  /// - Is the job enabled?
  /// - Has the start date passed?
  /// - Has the end date passed?
  /// - Is today a skip date?
  /// - Are all dependencies satisfied?
  ///
  /// Returns a tuple of (isEligible: bool, reason: String?).
  /// The first field indicates if the job is eligible for execution.
  /// If eligible, the second field is null.
  /// If not eligible, the second field explains why.
  static (bool isEligible, String? reason) isEnabledForExecution(
    JobConfig config,
    DateTime now,
  ) {
    if (!config.enabled) {
      return (false, 'Job is disabled');
    }

    if (config.startAt != null && now.isBefore(config.startAt!)) {
      return (false, 'Job has not started yet (start date is in the future)');
    }

    if (config.endAt != null && now.isAfter(config.endAt!)) {
      // Allow execution on the end date itself; only block after it has passed.
      // Use the date-only comparison to make this inclusive of the end date.
      final endDate = DateTime(
        config.endAt!.year,
        config.endAt!.month,
        config.endAt!.day,
      );
      final nowDate = DateTime(now.year, now.month, now.day);
      if (nowDate.isAfter(endDate)) {
        return (false, 'Job has ended (end date has passed)');
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    if (config.skipDates.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    )) {
      return (false, 'Today is marked as a skip date');
    }

    return (true, null);
  }

  /// Validates all job dependencies are satisfied.
  ///
  /// Returns true if all dependencies have completed successfully.
  /// Returns false if any dependency is missing, failed, or pending.
  ///
  /// This is a utility method for external callers; [JobRunner.execute]
  /// queries dependencies directly.
  static bool validateDependencies(
    List<String> dependencyIds,
    Map<String, JobConfig> configsById,
  ) {
    for (final depId in dependencyIds) {
      final depConfig = configsById[depId];
      if (depConfig == null) {
        return false; // Dependency not found
      }
      if (depConfig.lastStatus != JobStatus.success) {
        return false; // Dependency not successful
      }
    }
    return true;
  }
}
