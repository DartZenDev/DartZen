import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Represents a failure encountered during the generation of a Cloud Task request.
///
/// This error is returned when the input parameters for a job execution
/// violate the structural requirements of the Cloud Tasks API.
@internal
class JobTaskCreationError extends ZenError {
  /// Creates a [JobTaskCreationError] with a descriptive message explaining the failure.
  const JobTaskCreationError(super.message);
}

/// Represents a failure encountered during the dispatch of a Cloud Task.
///
/// This error is returned when the prepared request cannot be sent to the
/// Cloud Tasks service (e.g., network error or server rejection).
@internal
class JobDispatchError extends ZenError {
  /// Creates a [JobDispatchError] with a descriptive message explaining the failure.
  const JobDispatchError(super.message);
}

/// A data transfer object representing a job submission.
///
/// Encapsulates the unique identifier and the optional data payload required
/// for a single job execution attempt.
@internal
class JobSubmission {
  /// The unique identifier that maps to a registered job definition.
  final String id;

  /// The optional data payload to be passed to the job handler.
  final Map<String, dynamic>? payload;

  /// Constructs a [JobSubmission] instance with the specified [id] and optional [payload].
  const JobSubmission(this.id, {this.payload});
}

/// A value object representing a fully prepared Google Cloud Task request.
///
/// Contains the complete structural data (URL, headers, and body).
///
/// **Authentication**: Real dispatchers ([GcpJobDispatcher]) typically require
/// a valid Google Identity token (IAM/ADC) in the `Authorization` header.
@internal
class CloudTaskRequest {
  /// The absolute endpoint URL for the Cloud Tasks API request.
  final String url;

  /// The collection of HTTP headers required for the request.
  final Map<String, String> headers;

  /// The JSON-formatted and Base64-encoded string containing the task payload.
  final String body;

  /// The ISO-8601 timestamp indicating when the task should be performed.
  ///
  /// If null, the task is scheduled for immediate execution.
  final String? scheduleTime;

  /// Constructs a [CloudTaskRequest] with the provided execution parameters.
  const CloudTaskRequest({
    required this.url,
    required this.headers,
    required this.body,
    this.scheduleTime,
  });
}

/// A deterministic transformer for preparing job execution requests for Google Cloud Tasks.
///
/// This adapter is responsible solely for mapping internal job concepts into
/// valid Cloud Tasks API structures.
@internal
class CloudTasksAdapter {
  final String _projectId;
  final String _locationId;
  final String _queueId;
  final String _serviceUrl;

  /// Constructs a [CloudTasksAdapter] with the specified GCP infrastructure coordinates.
  const CloudTasksAdapter({
    required String projectId,
    required String locationId,
    required String queueId,
    required String serviceUrl,
  }) : _projectId = projectId,
       _locationId = locationId,
       _queueId = queueId,
       _serviceUrl = serviceUrl;

  /// Transforms a [JobSubmission] into a [CloudTaskRequest], optionally applying a [delay].
  ///
  /// This operation is pure and deterministic.
  ZenResult<CloudTaskRequest> toRequest(
    JobSubmission job, {
    Duration? delay,
    ZenTimestamp? currentTime,
  }) {
    if (job.id.isEmpty) {
      return const ZenResult.err(
        JobTaskCreationError('Job ID cannot be empty.'),
      );
    }

    final parent =
        'projects/$_projectId/locations/$_locationId/queues/$_queueId';
    final url = 'https://cloudtasks.googleapis.com/v2/$parent/tasks';

    final Map<String, dynamic> taskBody = {
      'httpRequest': {
        'httpMethod': 'POST',
        'url': '$_serviceUrl/jobs/trigger',
        'headers': {'Content-Type': 'application/json'},
        'body': base64Encode(
          utf8.encode(jsonEncode({'jobId': job.id, 'payload': job.payload})),
        ),
      },
    };

    String? scheduleTimeStr;
    if (delay != null) {
      final baseTime = currentTime?.value ?? DateTime.now().toUtc();
      scheduleTimeStr = baseTime.add(delay).toUtc().toIso8601String();
      taskBody['scheduleTime'] = scheduleTimeStr;
    }

    return ZenResult.ok(
      CloudTaskRequest(
        url: url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task': taskBody}),
        scheduleTime: scheduleTimeStr,
      ),
    );
  }
}

/// Interface for dispatching a Cloud Task request.
@internal
abstract class JobDispatcher {
  /// Sends the fully prepared [request] to the target queue or simulator.
  Future<ZenResult<void>> dispatch(CloudTaskRequest request);
}

/// A dispatcher that sends requests to the real Google Cloud Tasks API.
///
/// **Security Notice**: This dispatcher requires the underlying `_httpClient`
/// to be authenticated (e.g., using Application Default Credentials or
/// an injected `Authorization` header). You can use `headerInjector` to
/// provide dynamic tokens.
@internal
class GcpJobDispatcher implements JobDispatcher {
  final http.Client _httpClient;
  final Map<String, String> Function()? _headerInjector;

  /// Creates a dispatcher.
  ///
  /// [headerInjector] can be used to add authentication headers to the request.
  GcpJobDispatcher(
    this._httpClient, {
    Map<String, String> Function()? headerInjector,
  }) : _headerInjector = headerInjector;

  @override
  Future<ZenResult<void>> dispatch(CloudTaskRequest request) async {
    try {
      final headers = {
        ...request.headers,
        if (_headerInjector != null) ..._headerInjector(),
      };

      final response = await _httpClient.post(
        Uri.parse(request.url),
        headers: headers,
        body: request.body,
      );

      if (response.statusCode >= 300) {
        return ZenResult.err(
          JobDispatchError(
            'Failed to dispatch Cloud Task (status: ${response.statusCode}): ${response.body}',
          ),
        );
      }

      return const ZenResult.ok(null);
    } catch (e) {
      return ZenResult.err(
        JobDispatchError('Transport error during dispatch: $e'),
      );
    }
  }
}

/// A dispatcher that simulates task creation by logging for development.
@internal
class SimulatedJobDispatcher implements JobDispatcher {
  @override
  Future<ZenResult<void>> dispatch(CloudTaskRequest request) async {
    ZenLogger.instance.info('Triggering Cloud Task (Simulated)');
    ZenLogger.instance.info(
      'Job Request (Simulated): url=${request.url}, body=${request.body}',
    );
    return const ZenResult.ok(null);
  }
}
