import 'package:meta/meta.dart';

import '../executor_config.dart';

/// Optional per-call overrides for heavy task execution destination.
///
/// Allows explicit override of the default [queueId] and [serviceUrl]
/// configured in [ZenExecutorConfig].
///
/// **Override policy**:
/// - Override is permitted only through this explicit class.
/// - Override is optional; absence means use constructor-provided values.
/// - No implicit fallbacks, env lookups, or magic defaults.
///
/// Example:
/// ```dart
/// await executor.execute(
///   heavyTask,
///   overrides: ExecutionOverrides(
///     queueId: 'special-queue',
///     serviceUrl: 'https://special-service.run.app',
///   ),
/// );
/// ```
@immutable
class ExecutionOverrides {
  /// Creates an explicit override for heavy task execution destination.
  ///
  /// Both fields are optional. If provided, they replace the corresponding
  /// values from [ZenExecutorConfig] for this single execution.
  const ExecutionOverrides({this.queueId, this.serviceUrl});

  /// Overrides the default Cloud Tasks queue identifier.
  final String? queueId;

  /// Overrides the default service URL for heavy task handling.
  final String? serviceUrl;
}
