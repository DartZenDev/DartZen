import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  group('CacheAIUsageStore reset behavior', () {
    test(
      'reset clears in-memory surface and persists zeros to cache',
      () async {
        // Use explicit in-memory cache for deterministic tests.
        final cache = InMemoryCache();

        final store = CacheAIUsageStore.withClient(
          cache,
          flushInterval: const Duration(milliseconds: 100),
        );

        store.recordUsage('textGeneration', 3.25);
        expect(store.getMethodUsage('textGeneration'), closeTo(3.25, 1e-9));

        // Allow flush to persist initial value
        await Future<void>.delayed(const Duration(milliseconds: 250));

        // Now reset and allow persistence of zeros
        store.reset();
        expect(store.getMethodUsage('textGeneration'), equals(0.0));

        await Future<void>.delayed(const Duration(milliseconds: 250));

        final now = DateTime.now().toUtc();
        final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final key = 'dartzen:ai:usage:textGeneration:$suffix';

        final persisted = await cache.get<double>(key);
        expect(persisted, isNotNull);
        expect(persisted, closeTo(0.0, 1e-9));

        await store.close();
      },
    );
  });
}
