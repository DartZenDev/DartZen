import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

String _yearMonthSuffix() {
  final now = DateTime.now().toUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

void main() {
  group('CacheAIUsageStore (InMemoryCache)', () {
    late CacheClient cache;
    late CacheAIUsageStore store;

    setUp(() async {
      cache = InMemoryCache();
      store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(milliseconds: 100),
      );
      // ensure initial load is complete
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() async {
      await store.close();
    });

    test('recordUsage updates memory and flushes to cache', () async {
      store.recordUsage('textGeneration', 1.5);

      // immediate in-memory read
      expect(store.getMethodUsage('textGeneration'), closeTo(1.5, 1e-6));

      // wait for background flush to happen
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final suffix = _yearMonthSuffix();
      final gKey = 'dartzen:ai:usage:global:$suffix';
      final mKey = 'dartzen:ai:usage:textGeneration:$suffix';

      final gVal = await cache.get<double>(gKey);
      final mVal = await cache.get<double>(mKey);

      expect(gVal, closeTo(1.5, 1e-6));
      expect(mVal, closeTo(1.5, 1e-6));
    });

    test('reset clears memory and persists zeros', () async {
      store.recordUsage('embeddings', 2.0);
      expect(store.getMethodUsage('embeddings'), closeTo(2.0, 1e-6));

      store.reset();

      // memory should be cleared immediately
      expect(store.getGlobalUsage(), closeTo(0.0, 1e-6));
      expect(store.getMethodUsage('embeddings'), closeTo(0.0, 1e-6));

      // wait for persistence
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final suffix = _yearMonthSuffix();
      final gKey = 'dartzen:ai:usage:global:$suffix';
      final mKey = 'dartzen:ai:usage:embeddings:$suffix';

      final gVal = await cache.get<double>(gKey);
      final mVal = await cache.get<double>(mKey);

      expect(gVal, closeTo(0.0, 1e-6));
      expect(mVal, closeTo(0.0, 1e-6));
    });
  });
}
