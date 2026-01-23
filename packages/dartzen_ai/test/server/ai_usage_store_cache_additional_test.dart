import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

class RecordingCache implements CacheClient {
  final Map<String, Object> _store = {};
  final List<SetCall> setCalls = [];
  final List<String> getCalls = [];
  bool clearCalled = false;

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    _store[key] = value;
    setCalls.add(SetCall(key, value, ttl));
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
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    clearCalled = true;
    _store.clear();
  }

  // expose for tests
  void seed(String key, Object value) => _store[key] = value;
}

class SetCall {
  SetCall(this.key, this.value, this.ttl);
  final String key;
  final Object value;
  final Duration? ttl;
}

class ThrowingCache extends RecordingCache {
  final Set<String> throwForKeys;
  ThrowingCache([this.throwForKeys = const {}]);

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    if (throwForKeys.contains(key)) throw StateError('boom');
    return super.set(key, value, ttl: ttl);
  }
}

void main() {
  group('CacheAIUsageStore additional', () {
    test('reset writes zeros to exact cache keys without ttl', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      // perform reset
      cache.setCalls.clear();
      store.reset();

      // allow async reset to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now().toUtc();
      final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final expectedGlobal = 'dartzen:ai:usage:global:$suffix';
      final expectedText = 'dartzen:ai:usage:textGeneration:$suffix';
      final expectedEmb = 'dartzen:ai:usage:embeddings:$suffix';
      final expectedClass = 'dartzen:ai:usage:classification:$suffix';

      final keys = cache.setCalls.map((c) => c.key).toList();
      expect(
        keys,
        containsAll([expectedGlobal, expectedText, expectedEmb, expectedClass]),
      );

      // Ensure the reset writes zeros and does not provide TTL
      final zeroCalls = cache.setCalls
          .where((c) => (c.value as double) == 0.0)
          .toList();
      expect(zeroCalls.length, greaterThanOrEqualTo(4));
      for (final c in zeroCalls) {
        expect(c.ttl, isNull, reason: 'reset should call set without ttl');
      }

      await store.close();
    });

    test(
      'flush swallows cache.set errors and in-memory counters still update',
      () async {
        // make the cache throw for the global key only
        final now = DateTime.now().toUtc();
        final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final badGlobal = 'dartzen:ai:usage:global:$suffix';

        final cache = ThrowingCache({badGlobal});
        final store = CacheAIUsageStore.withClient(
          cache,
          flushInterval: const Duration(hours: 1),
        );

        // Should not throw despite underlying cache.set throwing
        store.recordUsage('textGeneration', 2.5);

        // allow async flush
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // in-memory values must have been updated
        expect(store.getMethodUsage('textGeneration'), equals(2.5));
        expect(store.getGlobalUsage(), equals(2.5));

        // The cache may have swallowed the global error before setting method
        // keys; the important invariant is that in-memory counters were updated
        // and no exception propagated.

        await store.close();
      },
    );
  });
}
