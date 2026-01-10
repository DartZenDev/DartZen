import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:http/http.dart' as http;

import 'cloud_tasks_adapter.dart';
import 'job_runner.dart';
import 'job_store.dart';
import 'master_job.dart';
import 'models/job_context.dart';
import 'models/job_definition.dart';
import 'models/job_type.dart';

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

  final Map<String, JobDefinition> _registry = {};
  late final JobStore _store;
  late final JobRunner _runner;
  late final CloudTasksAdapter _cloudTasks;
  late final JobDispatcher _dispatcher;
  late final MasterJob _masterJob;
  late final TelemetryClient _telemetry;

  /// Reserved ID for the Master Job scheduler.
  static const String masterJobId = 'zen_master_scheduler';

  /// Creates a [ZenJobs] instance with Google Cloud Tasks configuration.
  ///
  /// Initialization sets up internal components like [JobStore] (Firestore interaction)
  /// and [MasterJob] (periodic batching).
  ///
  /// Automatically selects the appropriate [JobDispatcher] based on [dzIsPrd].
  ZenJobs({
    required String projectId,
    required String locationId,
    required String queueId,
    required String serviceUrl,
    http.Client? httpClient,
  }) {
    _telemetry = TelemetryClient(FirestoreTelemetryStore());
    _store = JobStore();

    _cloudTasks = CloudTasksAdapter(
      projectId: projectId,
      locationId: locationId,
      queueId: queueId,
      serviceUrl: serviceUrl,
    );

    if (dzIsPrd) {
      _dispatcher = GcpJobDispatcher(httpClient ?? http.Client());
    } else {
      _dispatcher = SimulatedJobDispatcher();
    }

    _runner = JobRunner(_store, _registry, _telemetry);
    _masterJob = MasterJob(_store, _telemetry, _runner.execute);
  }

  /// Creates a [ZenJobs] instance with explicitly injected dependencies.
  ///
  /// Primarily used for testing or advanced manual configuration.
  ZenJobs.custom({
    required JobStore store,
    required JobRunner runner,
    required CloudTasksAdapter cloudTasks,
    required JobDispatcher dispatcher,
    required MasterJob masterJob,
    required TelemetryClient telemetry,
  }) : _store = store,
       _runner = runner,
       _cloudTasks = cloudTasks,
       _dispatcher = dispatcher,
       _masterJob = masterJob,
       _telemetry = telemetry;

  /// Registers a [JobDefinition] in the system.
  ///
  /// Registration makes the job handler available for execution via [handleRequest]
  /// or [trigger]. Attempting to register multiple jobs with the same ID will
  /// log a warning and overwrite the earlier registration.
  void register(JobDefinition definition) {
    if (_registry.containsKey(definition.id)) {
      ZenLogger.instance.info(
        'WARNING: Overwriting job handler for ${definition.id}',
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
    final def = _registry[jobId];
    if (def == null) {
      return ZenResult.err(
        ZenNotFoundError('Job definition not found: $jobId'),
      );
    }
    if (def.type != JobType.endpoint) {
      return const ZenResult.err(
        ZenValidationError(
          'Only endpoint jobs can be triggered via trigger().',
        ),
      );
    }

    final requestResult = _cloudTasks.toRequest(
      JobSubmission(jobId, payload: payload),
      delay: delay,
      currentTime: currentTime,
    );

    if (requestResult.isFailure) {
      return ZenResult.err(requestResult.errorOrNull!);
    }

    return _dispatcher.dispatch(requestResult.dataOrNull!);
  }

  /// Processes an incoming HTTP request containing a job execution command.
  ///
  /// This is the entry point for webhooks from Cloud Tasks or Cloud Scheduler.
  ///
  /// [request] can be a [Map] or a JSON-encoded [String].
  ///
  /// Returns a status code (e.g., 200 for success, 500 for retryable failure).
  Future<int> handleRequest(dynamic request) async {
    Map<String, dynamic> body;
    if (request is Map<String, dynamic>) {
      body = request;
    } else if (request is String) {
      try {
        body = jsonDecode(request) as Map<String, dynamic>;
      } catch (e) {
        return 400;
      }
    } else {
      return 500;
    }

    final jobId = body['jobId'] as String?;
    final payload = body['payload'] as Map<String, dynamic>?;

    if (jobId == null) return 400;

    ZenResult<void> result;
    if (jobId == masterJobId) {
      result = await _masterJob.run(
        JobContext(
          jobId: masterJobId,
          executionTime: DateTime.now(),
          attempt: 1,
        ),
      );
    } else {
      result = await _runner.execute(jobId, payload: payload);
    }

    return result.fold((data) => 200, (error) {
      ZenLogger.instance.error(
        'Job execution failed for $jobId: ${error.message}',
        error: error,
      );
      // Map common errors to appropriate HTTP status codes
      if (error is ZenNotFoundError) return 404;
      if (error is ZenValidationError) return 400;
      return 500;
    });
  }
}
