import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

class SimpleRecordingCache implements CacheClient {
  final Map<String, Object> _store = {};
  final List<String> getCalls = [];
  final List<String> deleted = [];
  final List<String> cleared = [];
  final List<String> setKeys = [];

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    _store[key] = value;
    setKeys.add(key);
  }

  @override
  Future<T?> get<T>(String key) async {
    getCalls.add(key);
    final v = _store[key];
    if (v == null) return null;
    return v as T;
  }

  @override
  Future<void> delete(String key) async {
    deleted.add(key);
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    cleared.add('cleared');
    _store.clear();
  }
}

class ThrowOnSetCache extends SimpleRecordingCache {
  final Set<String> throwFor;

  ThrowOnSetCache([this.throwFor = const {}]);

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    if (throwFor.contains(key)) throw StateError('set-failed');
    return super.set(key, value, ttl: ttl);
  }
}

void main() {
  group('CacheAIUsageStore remaining branches', () {
    test('reset swallows cache.set errors', () async {
      final now = DateTime.now().toUtc();
      final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final badGlobal = 'dartzen:ai:usage:global:$suffix';

      final cache = ThrowOnSetCache({badGlobal});
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      // Populate some in-memory counters first so reset clears them.
      store.recordUsage('textGeneration', 3.0);
      expect(store.getGlobalUsage(), equals(3.0));

      // Calling reset should not throw even if underlying cache.set fails
      store.reset();

      // wait a short moment for async reset to run
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // In-memory counters must be cleared regardless of cache failures
      expect(store.getGlobalUsage(), equals(0.0));
      expect(store.getMethodUsage('textGeneration'), equals(0.0));

      await store.close();
    });

    test('recordUsage after close does not flush to cache', () async {
      final cache = SimpleRecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      // Close the store which sets _closed and cancels timers.
      await store.close();

      // Clear any sets caused by close's final flush attempt.
      cache.setKeys.clear();

      // Recording usage after close should update in-memory counters but
      // should not attempt to persist to the cache (flush early-returns).
      store.recordUsage('embeddings', 1.25);

      // allow any async fire-and-forget tasks to run
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(store.getMethodUsage('embeddings'), equals(1.25));
      expect(store.getGlobalUsage(), equals(1.25));
      expect(
        cache.setKeys,
        isEmpty,
        reason: 'No cache.set should be attempted after close',
      );

      // ensure tidy shutdown (no-op but safe)
      await store.close();
    });
  });
}
