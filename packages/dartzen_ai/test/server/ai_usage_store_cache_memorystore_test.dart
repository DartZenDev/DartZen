import 'dart:async';

import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

class _DummyTransport implements RedisTransport {
  @override
  Future<String> sendCommand(List<String> args) async {
    final cmd = args.isNotEmpty ? args[0].toUpperCase() : '';
    if (cmd == 'GET') {
      // return Redis null bulk reply
      return r'$-1\r\n';
    }
    // Generic OK
    return '+OK\\r\\n';
  }
}

class TestMemorystoreCache extends MemorystoreCache {
  bool closedCalled = false;

  TestMemorystoreCache()
    : super(
        host: 'localhost',
        port: 1,
        useTls: false,
        transport: _DummyTransport(),
      );

  @override
  Future<void> close() async {
    closedCalled = true;
    throw StateError('close-failed');
  }
}

void main() {
  group('CacheAIUsageStore Memorystore behaviors', () {
    test('close swallows MemorystoreCache.close exceptions', () async {
      final mem = TestMemorystoreCache();
      final store = CacheAIUsageStore.withClient(
        mem,
        flushInterval: const Duration(hours: 1),
      );

      // No exception should propagate even though underlying close throws
      await store.close();
      expect(mem.closedCalled, isTrue);
    });

    test('connect returns a usable store (in-memory backend in dev)', () async {
      if (dzIsPrd) return; // skip in production-like test environments
      const cfg = CacheConfig(defaultTtl: Duration(minutes: 5));
      final store = await CacheAIUsageStore.connect(
        cfg,
        flushInterval: const Duration(hours: 1),
      );

      // New store should start with zeroed counters
      expect(store.getGlobalUsage(), equals(0.0));
      expect(store.getMethodUsage('textGeneration'), equals(0.0));

      await store.close();
    });
  });
}
