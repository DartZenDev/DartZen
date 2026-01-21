import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

class FakeCache implements CacheClient {
  final Map<String, Object> _store = {};

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    _store[key] = value;
  }

  @override
  Future<T?> get<T>(String key) async {
    final v = _store[key];
    if (v == null) return null;
    return v as T;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

void main() {
  group('CacheAIUsageStore basic behavior', () {
    test('recordUsage updates in-memory surface and reset clears it', () async {
      final cache = FakeCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(milliseconds: 50),
      );

      // Initially zero
      expect(store.getGlobalUsage(), equals(0.0));
      expect(store.getMethodUsage('textGeneration'), equals(0.0));

      store.recordUsage('textGeneration', 5.0);

      // in-memory surface should update immediately
      expect(store.getGlobalUsage(), equals(5.0));
      expect(store.getMethodUsage('textGeneration'), equals(5.0));

      // allow async flush to happen
      await Future.delayed(const Duration(milliseconds: 100));

      // Reset should clear in-memory surface
      store.reset();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(store.getGlobalUsage(), equals(0.0));
      expect(store.getMethodUsage('textGeneration'), equals(0.0));

      await store.close();
    });
  });
}
