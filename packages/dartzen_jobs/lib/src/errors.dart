/// Thrown when a job descriptor or handler is expected but not present.
///
/// This error is used to enforce the descriptor-first policy: runtime
/// operations must be performed by an `Executor` and require a registered
/// `JobDescriptor` and a registered handler.
class MissingDescriptorException implements Exception {
  /// Human-readable message describing the missing descriptor condition.
  final String message;

  /// Create a new [MissingDescriptorException] with [message].
  const MissingDescriptorException(this.message);

  @override
  String toString() => 'MissingDescriptorException: $message';
}
