/// Base class for all cache-related errors.
sealed class CacheError implements Exception {
  /// A human-readable error message.
  final String message;

  /// Optional underlying error that caused this cache error.
  final Object? cause;

  /// Optional stack trace from the underlying error.
  final StackTrace? stackTrace;

  const CacheError(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    if (cause != null) {
      return '$runtimeType: $message (caused by: $cause)';
    }
    return '$runtimeType: $message';
  }
}

/// Thrown when the cache backend cannot be reached or connected to.
///
/// This typically indicates:
/// - Redis server is unreachable
/// - Network connectivity issues
/// - Authentication failures
final class CacheConnectionError extends CacheError {
  /// Creates a connection error with the given [message].
  const CacheConnectionError(super.message, {super.cause, super.stackTrace});
}

/// Thrown when a value cannot be serialized or deserialized.
///
/// This typically indicates:
/// - Value contains non-JSON-serializable types
/// - Stored data is corrupted
/// - Type mismatch during deserialization
final class CacheSerializationError extends CacheError {
  /// The key that was being accessed when the error occurred.
  final String key;

  /// Creates a serialization error for the given [key].
  const CacheSerializationError(
    super.message,
    this.key, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message (key: $key)';
}

/// Thrown when a cache operation fails for reasons other than connection or serialization.
///
/// This is a catch-all for unexpected operational failures.
final class CacheOperationError extends CacheError {
  /// The operation that failed (e.g., 'set', 'get', 'delete', 'clear').
  final String operation;

  /// Creates an operation error for the given [operation].
  const CacheOperationError(
    super.message,
    this.operation, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message (operation: $operation)';
}
