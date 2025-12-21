import 'package:dartzen_core/dartzen_core.dart';

import 'cache_store.dart';

/// An in-memory implementation of [CacheStore] for local development.
class InMemoryCacheStore implements CacheStore {
  final Map<String, _InMemoryEntry> _storage = {};

  @override
  Future<ZenResult<String?>> get(String key) async {
    final entry = _storage[key];
    if (entry == null) return const ZenResult.ok(null);

    if (entry.isExpired) {
      _storage.remove(key);
      return const ZenResult.ok(null);
    }

    return ZenResult.ok(entry.value);
  }

  @override
  Future<ZenResult<void>> set(String key, String value, Duration ttl) async {
    _storage[key] = _InMemoryEntry(
      value: value,
      expiry: DateTime.now().add(ttl),
    );

    // Simple eviction policy for dev memory safety
    if (_storage.length > 1000) {
      _storage.remove(_storage.keys.first);
    }

    return const ZenResult.ok(null);
  }

  @override
  Future<ZenResult<void>> delete(String key) async {
    _storage.remove(key);
    return const ZenResult.ok(null);
  }
}

class _InMemoryEntry {
  _InMemoryEntry({required this.value, required this.expiry});
  final String value;
  final DateTime expiry;

  bool get isExpired => DateTime.now().isAfter(expiry);
}
