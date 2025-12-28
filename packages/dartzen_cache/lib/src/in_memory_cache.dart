import 'dart:convert';

import 'cache_client.dart';
import 'cache_errors.dart';

/// A cache entry with value and optional expiration time.
class _CacheEntry {
  final Object value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }
}

/// In-memory cache implementation using a Map.
///
/// This cache stores entries in memory and supports TTL-based expiration.
/// Expired entries are removed lazily on access.
///
/// This implementation is suitable for:
/// - Local development
/// - Unit testing
/// - Lightweight deployments
///
/// Example:
/// ```dart
/// final cache = InMemoryCache(defaultTtl: Duration(minutes: 10));
/// await cache.set('key', 'value');
/// final value = await cache.get<String>('key');
/// ```
class InMemoryCache implements CacheClient {
  final Map<String, _CacheEntry> _storage = {};

  /// Default time-to-live for cache entries.
  final Duration? defaultTtl;

  /// Creates an in-memory cache with optional [defaultTtl].
  ///
  /// If [defaultTtl] is null, entries will not expire automatically.
  InMemoryCache({this.defaultTtl});

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    try {
      // Validate that value is JSON-serializable
      jsonEncode(value);

      final effectiveTtl = ttl ?? defaultTtl;
      final expiresAt = effectiveTtl != null
          ? DateTime.now().add(effectiveTtl)
          : null;

      _storage[key] = _CacheEntry(value, expiresAt);
    } on JsonUnsupportedObjectError catch (e, stack) {
      throw CacheSerializationError(
        'Value is not JSON-serializable',
        key,
        cause: e,
        stackTrace: stack,
      );
    } catch (e, stack) {
      throw CacheOperationError(
        'Failed to set cache entry',
        'set',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    try {
      final entry = _storage[key];

      if (entry == null) {
        return null;
      }

      if (entry.isExpired) {
        _storage.remove(key);
        return null;
      }

      // For primitives and already-typed values, return as-is
      if (entry.value is T) {
        return entry.value as T;
      }

      // For complex types, round-trip through JSON to ensure type safety
      final encoded = jsonEncode(entry.value);
      final decoded = jsonDecode(encoded);

      if (decoded is! T) {
        throw CacheSerializationError(
          'Stored value type ${decoded.runtimeType} does not match requested type $T',
          key,
        );
      }

      return decoded;
    } on CacheSerializationError {
      rethrow;
    } catch (e, stack) {
      throw CacheOperationError(
        'Failed to get cache entry',
        'get',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
