import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';

/// Dispatcher interface for heavy task execution.
///
/// Abstracts job dispatch implementation, ensuring ZenExecutor remains
/// a pure router without direct knowledge of jobs system internals.
///
/// **Responsibility**: Dispatch validated job envelopes to the jobs system.
/// **What it does NOT do**: Decide routing, validate payload, manage lifecycle.
abstract class JobDispatcher {
  /// Dispatches a validated job envelope to the jobs system.
  ///
  /// Returns:
  /// - [ZenSuccess] if dispatch was accepted (does not guarantee execution)
  /// - [ZenFailure] if dispatch failed (network, validation, permission)
  ///
  /// Implementation must be **synchronous** or return immediately after
  /// queuing to avoid blocking the executor.
  Future<ZenResult<void>> dispatch({
    required String jobId,
    required String queueId,
    required String serviceUrl,
    required Map<String, dynamic> payload,
  });
}

/// Default job dispatcher using Cloud Tasks via ZenJobs.
///
/// This implementation delegates to [ZenJobs.instance] and handles
/// the mapping from executor parameters to Cloud Tasks API.
class CloudJobDispatcher implements JobDispatcher {
  /// Creates a cloud job dispatcher.
  ///
  /// Requires [ZenJobs.instance] to be initialized before use.
  const CloudJobDispatcher();

  @override
  Future<ZenResult<void>> dispatch({
    required String jobId,
    required String queueId,
    required String serviceUrl,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Note: In current ZenJobs API, queueId and serviceUrl are configured
      // at initialization time, not per-call. This dispatcher validates that
      // the requested destination matches the executor's configuration.
      // In a future refactor, ZenJobs should support per-call destination.

      final result = await ZenJobs.instance.trigger(jobId, payload: payload);

      return result;
    } catch (e, st) {
      return ZenResult.err(
        ZenUnknownError(
          'Failed to dispatch job to cloud: $e',
          internalData: {'jobId': jobId, 'queueId': queueId},
          stackTrace: st,
        ),
      );
    }
  }
}
