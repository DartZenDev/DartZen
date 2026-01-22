import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

class RecordingCache implements CacheClient {
  final Map<String, Object> _store = {};
  final List<SetCall> setCalls = [];
  final List<String> getCalls = [];
  final List<String> deleteCalls = [];
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
    deleteCalls.add(key);
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    clearCalled = true;
    _store.clear();
  }
}

class SetCall {
  SetCall(this.key, this.value, this.ttl);
  final String key;
  final Object value;
  final Duration? ttl;
}

void main() {
  group('CacheAIUsageStore', () {
    test('recordUsage triggers async flush to cache with TTL', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1), // long to avoid timer-based flush
      );

      store.recordUsage('textGeneration', 3.5);

      // allow async flush
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Check that set was called
      expect(
        cache.setCalls.any((c) => c.key.contains('textGeneration')),
        isTrue,
      );
      expect(
        cache.setCalls.any((c) => c.key.contains('global')),
        isTrue,
      );

      // Verify TTL was provided
      final globalCall = cache.setCalls.firstWhere((c) => c.key.contains('global'));
      expect(globalCall.ttl, isNotNull);
      expect(globalCall.ttl!.inSeconds, greaterThan(0));

      await store.close();
    });

    test('flush sets year-month suffix in cache keys', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      store.recordUsage('embeddings', 1.0);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now().toUtc();
      final expectedSuffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      expect(
        cache.setCalls.any((c) => c.key.contains(expectedSuffix)),
        isTrue,
        reason: 'Keys should include year-month suffix like $expectedSuffix',
      );

      await store.close();
    });

    test('reset clears in-memory and writes zeros to cache', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      store.recordUsage('classification', 5.0);
      expect(store.getGlobalUsage(), equals(5.0));

      cache.setCalls.clear();

      store.reset();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(store.getGlobalUsage(), equals(0.0));
      expect(store.getMethodUsage('classification'), equals(0.0));

      // Verify cache was updated with zeros
      final zeroCalls = cache.setCalls.where((c) => (c.value as double) == 0.0).toList();
      expect(zeroCalls.length, greaterThanOrEqualTo(3)); // global + methods

      await store.close();
    });

    test('flush interval triggers periodic flush', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(milliseconds: 30),
      );

      store.recordUsage('textGeneration', 1.0);
      cache.setCalls.clear();

      // wait for one or two flush intervals
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Periodic timer should have flushed at least once
      expect(cache.setCalls.isNotEmpty, isTrue);

      await store.close();
    });

    test('close flushes and cancels timer', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(milliseconds: 30),
      );

      store.recordUsage('embeddings', 2.0);
      cache.setCalls.clear();

      await store.close();

      // Final flush should have happened
      expect(
        cache.setCalls.any((c) => c.key.contains('embeddings')),
        isTrue,
      );

      final beforeCount = cache.setCalls.length;

      // wait for what would have been another flush interval
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // No additional flushes should occur after close
      expect(cache.setCalls.length, equals(beforeCount));
    });

    test('getMethodUsage returns 0.0 for unknown method', () {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      expect(store.getMethodUsage('unknownMethod'), equals(0.0));

      store.close();
    });

    test('multiple recordUsage calls accumulate', () {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      store.recordUsage('textGeneration', 1.0);
      store.recordUsage('textGeneration', 2.5);
      store.recordUsage('embeddings', 0.5);

      expect(store.getMethodUsage('textGeneration'), equals(3.5));
      expect(store.getMethodUsage('embeddings'), equals(0.5));
      expect(store.getGlobalUsage(), equals(4.0));

      store.close();
    });

    test('flush TTL matches seconds until month end (+60s slack)', () async {
      final cache = RecordingCache();
      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(hours: 1),
      );

      // Trigger a flush via recordUsage
      store.recordUsage('textGeneration', 1.0);

      // allow async flush
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final globalCall = cache.setCalls.firstWhere((c) => c.key.contains('global'));
      expect(globalCall.ttl, isNotNull);

      final now = DateTime.now().toUtc();
      final nextMonth = (now.month == 12) ? DateTime(now.year + 1).toUtc() : DateTime(now.year, now.month + 1).toUtc();
      final expectedSeconds = nextMonth.difference(now).inSeconds + 60;

      // allow a small timing discrepancy
      final actual = globalCall.ttl!.inSeconds;
      expect((actual - expectedSeconds).abs(), lessThanOrEqualTo(2), reason: 'TTL should equal seconds until month end + 60s slack');

      await store.close();
    });
  });
}
