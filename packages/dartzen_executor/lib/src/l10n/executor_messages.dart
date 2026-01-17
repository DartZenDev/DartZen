import 'package:dartzen_localization/dartzen_localization.dart';

/// Localized messages for the executor package.
///
/// Provides access to translated error and informational messages
/// used throughout task execution.
class ExecutorMessages {
  /// Creates an executor messages instance with the specified localization service and language.
  const ExecutorMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  /// Returns a localized message for task execution failure.
  String taskExecutionFailed(String taskType) => _translate(
    'executor.error.task_execution_failed',
    params: {'taskType': taskType},
    fallback: 'Task execution failed: $taskType',
  );

  /// Returns a localized message indicating heavy tasks must use the jobs system.
  String get heavyTaskRequired => _translate(
    'executor.error.heavy_task_required',
    fallback: 'Heavy task must be dispatched to jobs',
  );

  /// Returns a localized message for invalid job envelope structure.
  String get invalidEnvelope => _translate(
    'executor.error.invalid_envelope',
    fallback: 'Job envelope is invalid',
  );

  /// Returns a localized message indicating a task was routed to a local isolate.
  String get routedToIsolate => _translate(
    'executor.info.routed_to_isolate',
    fallback: 'Routed to isolate execution',
  );

  /// Returns a localized message for successful heavy task dispatch.
  String heavyTaskDispatched(String taskId) => _translate(
    'executor.info.heavy_task_dispatched',
    params: {'taskId': taskId},
    fallback: 'Heavy task dispatched: $taskId',
  );

  /// Returns a localized message for medium task timeout.
  String get mediumTaskTimeout => _translate(
    'executor.error.medium_task_timeout',
    fallback:
        'Medium task execution exceeded timeout. '
        'Task may be misclassified; consider marking as heavy.',
  );

  String _translate(
    String key, {
    Map<String, dynamic>? params,
    String? fallback,
  }) {
    try {
      return _localization.translate(
        key,
        language: _language,
        module: 'executor',
        params: params ?? const <String, dynamic>{},
      );
    } catch (_) {
      return fallback ?? key;
    }
  }
}
