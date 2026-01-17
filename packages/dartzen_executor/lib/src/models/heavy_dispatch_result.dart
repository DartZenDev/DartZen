/// Result of successful heavy task dispatch.
///
/// Represents the successful queuing of a heavy task for remote execution.
/// This is NOT an error state — it indicates that the task has been
/// successfully submitted to the jobs system and will execute asynchronously.
///
/// This value object exists to:
/// - Distinguish "successfully queued" from "execution error"
/// - Provide a clear semantic boundary for result flow
/// - Document that actual task result is unavailable at dispatch time
sealed class HeavyDispatchResult {
  /// Creates a successful dispatch result.
  ///
  /// [taskId]: The unique identifier of the dispatched task.
  const factory HeavyDispatchResult.dispatched({required String taskId}) =
      _Dispatched;
}

final class _Dispatched implements HeavyDispatchResult {
  const _Dispatched({required this.taskId});

  /// The unique identifier of the successfully dispatched task.
  final String taskId;

  @override
  String toString() => 'HeavyDispatchResult.dispatched(taskId: $taskId)';
}
