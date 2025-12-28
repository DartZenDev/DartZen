import 'cache_errors.dart';

/// Minimal cache interface providing basic cache operations.
///
/// Implementations must provide deterministic behavior with explicit error handling.
/// All operations are asynchronous to support both in-memory and remote backends.
abstract class CacheClient {
  /// Stores a [value] associated with [key].
  ///
  /// The [value] must be JSON-serializable. If [ttl] is provided, the entry
  /// will expire after the specified duration. Otherwise, the backend's
  /// default TTL (if configured) will be used.
  ///
  /// Throws [CacheSerializationError] if the value cannot be serialized.
  /// Throws [CacheConnectionError] if the backend is unavailable.
  /// Throws [CacheOperationError] for other operation failures.
  ///
  /// Example:
  /// ```dart
  /// await cache.set('user:123', {'name': 'Alice'});
  /// await cache.set('token', 'xyz', ttl: Duration(minutes: 5));
  /// ```
  Future<void> set(String key, Object value, {Duration? ttl});

  /// Retrieves the value associated with [key].
  ///
  /// Returns `null` if the key does not exist or has expired.
  /// The returned value is automatically deserialized to type [T].
  ///
  /// Throws [CacheSerializationError] if the stored value cannot be deserialized to [T].
  /// Throws [CacheConnectionError] if the backend is unavailable.
  /// Throws [CacheOperationError] for other operation failures.
  ///
  /// Example:
  /// ```dart
  /// final user = await cache.get<Map<String, dynamic>>('user:123');
  /// if (user != null) {
  ///   print(user['name']);
  /// }
  /// ```
  Future<T?> get<T>(String key);

  /// Deletes the entry associated with [key].
  ///
  /// Does nothing if the key does not exist.
  ///
  /// Throws [CacheConnectionError] if the backend is unavailable.
  /// Throws [CacheOperationError] for other operation failures.
  ///
  /// Example:
  /// ```dart
  /// await cache.delete('user:123');
  /// ```
  Future<void> delete(String key);

  /// Clears all entries from the cache.
  ///
  /// Use with caution in production environments.
  ///
  /// Throws [CacheConnectionError] if the backend is unavailable.
  /// Throws [CacheOperationError] for other operation failures.
  ///
  /// Example:
  /// ```dart
  /// await cache.clear();
  /// ```
  Future<void> clear();
}
