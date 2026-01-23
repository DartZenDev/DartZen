import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import 'task.dart';

/// A fixed-schema envelope for job payloads dispatched to the jobs system.
///
/// Structure:
/// ```json
/// {
///   "taskType": "MyTaskClass",
///   "metadata": {
///     "id": "task-123",
///     "weight": "heavy",
///     "schemaVersion": 1
///   },
///   "payload": {
///     "param1": "value1"
///   }
/// }
/// ```
///
/// **Schema characteristics**:
/// - Fixed structure for determinism and evolution.
/// - `taskType` identifies the task class for deserialization.
/// - `metadata` contains execution metadata (id, weight, version).
/// - `payload` contains task-specific data (JSON-serializable map).
///
/// **Schema evolution**:
/// - `metadata.schemaVersion` defaults to 1.
/// - Used only by downstream consumers; executor does not interpret it.
/// - Allows forward-compatible changes without breaking consumers.
@immutable
class JobEnvelope {
  /// Creates a job envelope with the specified task type, metadata, and payload.
  ///
  /// All fields are required to ensure schema completeness and determinism.
  const JobEnvelope({
    required this.taskType,
    required this.metadata,
    required this.payload,
  });

  /// Creates a job envelope from a [ZenTask].
  ///
  /// Extracts the task type from the runtime type name and serializes
  /// the task's metadata and payload.
  factory JobEnvelope.fromTask(ZenTask<dynamic> task) => JobEnvelope(
    taskType: task.runtimeType.toString(),
    metadata: task.metadata.toJson(),
    payload: task.toPayload(),
  );

  /// Creates a job envelope from a JSON map.
  ///
  /// Used by job workers to deserialize HTTP request payloads.
  factory JobEnvelope.fromJson(Map<String, dynamic> json) => JobEnvelope(
    taskType: json['taskType'] as String,
    metadata: json['metadata'] as Map<String, dynamic>,
    payload: json['payload'] as Map<String, dynamic>,
  );

  /// The fully-qualified task type name for deserialization.
  final String taskType;

  /// The task's execution metadata as a JSON map.
  final Map<String, dynamic> metadata;

  /// The task's business data as a JSON map.
  final Map<String, dynamic> payload;

  /// Converts this envelope to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'taskType': taskType,
    'metadata': metadata,
    'payload': payload,
  };

  /// Validates the envelope structure.
  ///
  /// Returns [ZenValidationError] if any required field is missing or malformed.
  ZenResult<void> validate() {
    if (taskType.isEmpty) {
      return const ZenResult.err(
        ZenValidationError('taskType cannot be empty'),
      );
    }
    if (metadata.isEmpty) {
      return const ZenResult.err(
        ZenValidationError('metadata cannot be empty'),
      );
    }
    if (!metadata.containsKey('id')) {
      return const ZenResult.err(
        ZenValidationError('metadata must contain id'),
      );
    }
    if (!metadata.containsKey('weight')) {
      return const ZenResult.err(
        ZenValidationError('metadata must contain weight'),
      );
    }
    return const ZenResult.ok(null);
  }
}
