import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import 'job_envelope.dart';
import 'task_rehydration.dart';

/// Internal helper for job worker context: rehydrate and execute heavy tasks.
///
/// **Purpose**: Provides a simple entry point for Cloud Run job handlers that
/// receive serialized [JobEnvelope] payloads from Cloud Tasks.
///
/// **Flow**:
/// 1. Job worker receives HTTP request with JobEnvelope JSON
/// 2. Deserializes to JobEnvelope
/// 3. Calls [rehydrateAndExecute] to create task from registry + execute
/// 4. Returns result to Cloud Tasks (success/failure)
///
/// **Internal API**: This is NOT exported from dartzen_executor. Job workers
/// in application code should use this pattern directly, not depend on this helper.
///
/// **Example** (in Cloud Run job handler):
/// ```dart
/// @CloudFunction()
/// Future<Response> handleHeavyTask(Request request) async {
///   final json = await request.readAsString();
///   final envelope = JobEnvelope.fromJson(jsonDecode(json));
///
///   final result = await rehydrateAndExecute(envelope);
///   return result.fold(
///     (value) => Response.ok('Task completed'),
///     (error) => Response.internalServerError(body: error.message),
///   );
/// }
/// ```
@internal
Future<ZenResult<dynamic>> rehydrateAndExecute(JobEnvelope envelope) async {
  try {
    // Rehydrate task from registry using factory
    final task = TaskFactoryRegistry.create(
      envelope.taskType,
      envelope.payload,
    );

    if (task == null) {
      return ZenResult.err(
        ZenUnknownError(
          'No factory registered for task type: ${envelope.taskType}',
          internalData: {'taskType': envelope.taskType},
        ),
      );
    }

    // Execute rehydrated task (no executor routing; direct execution)
    // Note: Uses invokeInternal() which may skip zone validation in worker context
    final result = await task.invokeInternal();

    return ZenResult.ok(result);
  } catch (e, st) {
    return ZenResult.err(
      ZenUnknownError(
        'Failed to rehydrate or execute task: ${envelope.taskType}',
        internalData: {'taskType': envelope.taskType, 'error': e.toString()},
        stackTrace: st,
      ),
    );
  }
}
