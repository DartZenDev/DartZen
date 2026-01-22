import 'dart:async';

// Import internal cache-backed store implementation for testing.
import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  group('CacheAIUsageStore', () {
    test('records usage and persists to cache', () async {
      // Use an explicit in-memory cache for tests to avoid depending on
      // compile-time environment flags.
      final cache = InMemoryCache();

      final store = CacheAIUsageStore.withClient(
        cache,
        flushInterval: const Duration(milliseconds: 100),
      );

      // Record some usage
      store.recordUsage('textGeneration', 1.5);

      // In-memory surface should reflect immediate change
      expect(store.getMethodUsage('textGeneration'), equals(1.5));
      expect(store.getGlobalUsage(), equals(1.5));

      // Wait for flush to persist into cache
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // Compute expected cache key suffix (YYYY-MM)
      final now = DateTime.now().toUtc();
      final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final key = 'dartzen:ai:usage:textGeneration:$suffix';

      final persisted = await cache.get<double>(key);
      expect(persisted, isNotNull);
      expect(persisted, closeTo(1.5, 1e-9));

      await store.close();
    });
  });
}
