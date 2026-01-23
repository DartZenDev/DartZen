import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  group('CacheAIUsageStore reset', () {
    test('reset clears in-memory counters and writes zeros to cache', () async {
      final cache = InMemoryCache();

      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(milliseconds: 50),
      );

      // Record usage to populate in-memory state and trigger a flush.
      store.recordUsage('textGeneration', 3.5);
      expect(store.getMethodUsage('textGeneration'), equals(3.5));
      expect(store.getGlobalUsage(), equals(3.5));

      // Now reset and verify in-memory values are cleared immediately.
      store.reset();
      expect(store.getMethodUsage('textGeneration'), equals(0.0));
      expect(store.getGlobalUsage(), equals(0.0));

      // Wait for the reset to persist into cache.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final now = DateTime.now().toUtc();
      final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final globalKey = 'dartzen:ai:usage:global:$suffix';
      final methodKey = 'dartzen:ai:usage:textGeneration:$suffix';

      final persistedGlobal = await cache.get<double>(globalKey);
      final persistedMethod = await cache.get<double>(methodKey);

      expect(persistedGlobal, isNotNull);
      expect(persistedGlobal, closeTo(0.0, 1e-9));
      expect(persistedMethod, isNotNull);
      expect(persistedMethod, closeTo(0.0, 1e-9));

      await store.close();
    });
  });
}
