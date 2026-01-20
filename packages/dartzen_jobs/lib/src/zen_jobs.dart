import 'package:dartzen_core/dartzen_core.dart';

import '../dartzen_jobs.dart' show JobType;
import 'cloud_tasks_adapter.dart' show CloudTasksAdapter, JobDispatcher;
import 'errors.dart';
import 'job_runner.dart' show JobRunner;
import 'master_job.dart' show MasterJob;
import 'models/job_definition.dart';
import 'models/job_type.dart' show JobType;

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
  /// Registration makes the job handler available for execution via [handleRequest]
  /// or [trigger]. Attempting to register multiple jobs with the same ID will
  /// log a warning and overwrite the earlier registration.
  void register(JobDescriptor definition) {
    if (_registry.containsKey(definition.id)) {
      ZenLogger.instance.info(
        'WARNING: Overwriting job descriptor for ${definition.id}',
      );
    }
    _registry[definition.id] = definition;
  }

  /// Triggers an endpoint-typed job by its ID.
  ///
  /// This prepares a request using [CloudTasksAdapter] and dispatches it via
  /// the environment-specific [JobDispatcher].
  ///
  /// [payload] is optional data passed to the job handler.
  /// [delay] can be used to schedule the execution in the future.
  /// [currentTime] allows deterministic scheduling (defaults to now).
  ///
  /// Returns [ZenNotFoundError] if the jobId is not registered, or
  /// [ZenValidationError] if it's not an [JobType.endpoint] job.
  Future<ZenResult<void>> trigger(
    String jobId, {
    Map<String, dynamic>? payload,
    Duration? delay,
    ZenTimestamp? currentTime,
  }) async {
    throw const MissingDescriptorException(
      'Direct triggering is forbidden. Use an Executor to schedule or trigger jobs.',
    );
  }

  /// Processes an incoming HTTP request containing a job execution command.
  ///
  /// This is the entry point for webhooks from Cloud Tasks or Cloud Scheduler.
  ///
  /// [request] can be a [Map] or a JSON-encoded [String].
  ///
  /// Returns a status code (e.g., 200 for success, 500 for retryable failure).
  Future<int> handleRequest(dynamic request) async {
    throw const MissingDescriptorException(
      'Direct HTTP handling is forbidden. Use an Executor to expose webhooks and handle requests.',
    );
  }
}
