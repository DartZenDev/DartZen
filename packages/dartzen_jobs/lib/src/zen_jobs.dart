import 'package:dartzen_core/dartzen_core.dart';

import '../dartzen_jobs.dart' show ZenJobsExecutor;
import 'job_runner.dart' show JobRunner;
import 'master_job.dart' show MasterJob;
import 'models/job_definition.dart';
import 'public/zen_jobs_executor.dart' show ZenJobsExecutor;

/// The main entry point for the DartZen Jobs system.
///
/// This singleton orchestrates job registration, execution (via [JobRunner]),
/// and specialized scheduling (via [MasterJob]).
///
/// To use, first initialize the singleton instance with a [ZenJobs] implementation,
/// then [register] your jobs.
class ZenJobs {
  static ZenJobs? _instance;

  /// Access the singleton instance of the jobs system.
  ///
  /// Throws [StateError] if the instance has not been initialized.
  static ZenJobs get instance {
    if (_instance == null) {
      throw StateError(
        'ZenJobs has not been initialized. Initialize it with a new ZenJobs(...) first.',
      );
    }
    return _instance!;
  }

  /// Sets the global [ZenJobs] singleton.
  static set instance(ZenJobs implementation) {
    _instance = implementation;
  }

  final Map<String, JobDescriptor> _registry = {};
  // Registry-only: runtime execution is owned by `Executor` implementations.

  /// Reserved ID for the Master Job scheduler.
  static const String masterJobId = 'zen_master_scheduler';

  /// Creates a registry-only `ZenJobs` instance.
  ///
  /// NOTE: runtime operations (triggering, scheduling, persistence) are the
  /// responsibility of an `Executor` implementation. This object only holds
  /// job descriptors for registration and discovery.
  ZenJobs();

  /// Read-only view of the registered job descriptors.
  Map<String, JobDescriptor> get descriptors => Map.unmodifiable(_registry);

  /// Creates a [ZenJobs] instance with explicitly injected dependencies.
  ///
  /// Primarily used for testing or advanced manual configuration.
  // Note: runtime dependencies (store, runner, adapters, dispatchers,
  // master scheduler, telemetry) are intentionally not owned by the
  // registry object. Provide these to an `Executor` implementation instead.

  /// Registers a [JobDescriptor] in the system.
  ///
  /// Registration makes the job descriptor available in the registry for
  /// executors to discover. Attempting to register multiple jobs with the
  /// same ID will log a warning and overwrite the earlier registration.
  ///
  /// NOTE: Actual job execution is handled by [ZenJobsExecutor] implementations.
  /// This method only manages the registry.
  void register(JobDescriptor definition) {
    if (_registry.containsKey(definition.id)) {
      ZenLogger.instance.info(
        'WARNING: Overwriting job descriptor for ${definition.id}',
      );
    }
    _registry[definition.id] = definition;
  }
}
