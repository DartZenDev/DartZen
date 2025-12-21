import 'package:dartzen_core/dartzen_core.dart';

/// A generic interface for a pluggable cache backend.
///
/// Implementations must handle serialization and TTL internally.
abstract class CacheStore {
  /// Retrieves a string value from the cache.
  Future<ZenResult<String?>> get(String key);

  /// Stores a string value in the cache with a specific [ttl].
  Future<ZenResult<void>> set(String key, String value, Duration ttl);

  /// Removes a value from the cache.
  Future<ZenResult<void>> delete(String key);
}
