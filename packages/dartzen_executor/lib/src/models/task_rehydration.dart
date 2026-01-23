import 'package:meta/meta.dart';

import '../../dartzen_executor.dart' show JobEnvelope;
import 'job_envelope.dart' show JobEnvelope;
import 'task.dart';

/// Factory type for reconstructing a [ZenTask] from a JSON payload.
///
/// Recommended convention for heavy tasks:
/// - Implement a `static fromPayload(Map<String, dynamic>)` on the task class
/// - Register that function in [TaskFactoryRegistry]
/// - Use the registry in job workers to rehydrate tasks by `taskType`
typedef TaskFactory<T> = ZenTask<T> Function(Map<String, dynamic> payload);

/// Minimal, in-memory registry to map `taskType` strings to factories.
///
/// This is intentionally small and explicit: consumers (e.g., jobs workers)
/// can look up a factory by the `taskType` stored in [JobEnvelope.taskType]
/// and rehydrate the task for execution.
@immutable
class TaskFactoryRegistry {
  const TaskFactoryRegistry._();

  static final Map<String, TaskFactory<dynamic>> _factories =
      <String, TaskFactory<dynamic>>{};

  /// Registers a factory for a given [taskType].
  static void register<T>(String taskType, TaskFactory<T> factory) {
    _factories[taskType] = factory;
  }

  /// Removes a registered factory.
  static void unregister(String taskType) {
    _factories.remove(taskType);
  }

  /// Clears all registered factories.
  static void clear() => _factories.clear();

  /// Creates a task instance using a previously registered factory.
  static ZenTask<dynamic>? create(
    String taskType,
    Map<String, dynamic> payload,
  ) {
    final factory = _factories[taskType];
    if (factory == null) return null;
    return factory(payload);
  }
}
