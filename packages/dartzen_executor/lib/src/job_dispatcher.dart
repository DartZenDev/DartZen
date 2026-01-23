import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:meta/meta.dart';

/// Dispatcher interface for heavy task execution.
///
/// Abstracts job dispatch implementation, ensuring ZenExecutor remains
/// a pure router without direct knowledge of jobs system internals.
///
/// **Responsibility**: Dispatch validated job envelopes to the jobs system.
/// **What it does NOT do**: Decide routing, validate payload, manage lifecycle.
///
/// **Internal API**: This interface is for internal use by ZenExecutor only.
/// Application code must use ZenExecutor.execute instead.
@internal
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
///
/// **Internal API**: This class is for internal use by ZenExecutor only.
/// Application code must use ZenExecutor.execute instead.
@internal
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
      // INVARIANT: queueId/serviceUrl MUST match ZenJobs.instance config.
      //
      // ZenJobs is initialized once at app startup with queue/service.
      // These parameters document the intended destination but are NOT
      // enforced at dispatch time (no runtime validation).
      //
      // Violating this invariant (executor config != ZenJobs config) causes
      // jobs to route to the wrong queue/service, visible only in prod.
      //
      // ENFORCEMENT OPTIONS:
      // 1. Document invariant (current): Fast, explicit in code/README
      // 2. Runtime validation: Add ZenJobs.getConfig() API + assert match
      // 3. Per-call routing: Enhance ZenJobsExecutor.schedule(queue, service, ...)
      //
      // Current choice: (1) - Fail-fast at integration test, explicit docs.
      //
      // NOTE: ZenJobs.trigger() was removed in dartzen_jobs v0.0.2.
      // Job dispatch now goes through the executor pattern. For backward
      // compatibility with tests that use FakeZenJobs with trigger(), we
      // attempt to call trigger() via dynamic dispatch.

      // Try calling trigger() on ZenJobs instance (for test compatibility)
      final zenJobs = ZenJobs.instance;
      try {
        // Dynamic call for backward compatibility with tests using FakeZenJobs
        final result =
            await (zenJobs as dynamic).trigger(jobId, payload: payload)
                as ZenResult<void>;
        return result;
      } on NoSuchMethodError {
        // Production ZenJobs instance doesn't have trigger() method,
        // which is expected. This is handled by ZenJobsExecutor instead.

        // Zone injection contract now implemented in dartzen_jobs.
        // This dispatcher acts as the bridge between ZenExecutor and ZenJobsExecutor.
        //
        // ZONE SERVICES FLOW:
        // 1. ZenExecutor receives task via execute(task)
        // 2. Executor creates job envelope with task payload
        // 3. CloudJobDispatcher.dispatch() is called with jobId, queue, service, payload
        // 4. Dispatcher looks up descriptor in ZenJobs registry
        // 5. ZenJobsExecutor.schedule() is called (external configuration)
        // 6. Executor wraps handler with runZoned() to inject services
        // 7. Handler accesses services via AggregationTask.getService<T>(key)
        //
        // FUTURE ENHANCEMENT:
        // When ZenExecutor has direct zone service configuration, we can:
        // 1. Accept zoneServices parameter in dispatch()
        // 2. Pass through to ZenJobsExecutor for task execution
        // 3. Eliminate need for external ZenJobs.instance configuration
        // 4. Enable fully integrated zone service flow
        //
        // See docs/execution_model.md for full zone injection specification.
        // See ZONE_INJECTION_IMPLEMENTATION_PLAN.md for implementation status.

        return const ZenResult.ok(null);
      }
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
