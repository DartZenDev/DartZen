import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCache', () {
    late InMemoryCache cache;

    setUp(() {
      cache = InMemoryCache();
    });

    test('set and get simple value', () async {
      await cache.set('key', 'value');
      final result = await cache.get<String>('key');
      expect(result, equals('value'));
    });

    test('set and get complex value', () async {
      final data = {'name': 'Alice', 'age': 30, 'active': true};
      await cache.set('user', data);
      final result = await cache.get<Map<String, dynamic>>('user');
      expect(result, equals(data));
    });

    test('get returns null for non-existent key', () async {
      final result = await cache.get<String>('missing');
      expect(result, isNull);
    });

    test('delete removes entry', () async {
      await cache.set('key', 'value');
      await cache.delete('key');
      final result = await cache.get<String>('key');
      expect(result, isNull);
    });

    test('clear removes all entries', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.clear();
      expect(await cache.get<String>('key1'), isNull);
      expect(await cache.get<String>('key2'), isNull);
    });

    test('TTL causes entry to expire', () async {
      await cache.set('key', 'value', ttl: const Duration(milliseconds: 100));
      expect(await cache.get<String>('key'), equals('value'));

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(await cache.get<String>('key'), isNull);
    });

    test('throws CacheSerializationError for non-serializable value', () async {
      expect(
        () => cache.set('key', () => 'function'),
        throwsA(isA<CacheSerializationError>()),
      );
    });

    test('throws CacheSerializationError for type mismatch', () async {
      await cache.set('key', 'string value');
      expect(
        () => cache.get<int>('key'),
        throwsA(isA<CacheSerializationError>()),
      );
    });
  });

  group('CacheFactory', () {
    test('creates cache based on environment', () {
      const config = CacheConfig(
        defaultTtl: Duration(minutes: 10),
        memorystoreHost: 'localhost',
        memorystorePort: 6379,
      );
      final cache = CacheFactory.create(config);
      expect(cache, isA<CacheClient>());
    });

    test('can create cache with full Memorystore configuration', () {
      const config = CacheConfig(
        memorystoreHost: '127.0.0.1',
        memorystorePort: 6379,
        useTls: false,
      );
      final cache = CacheFactory.create(config);
      expect(cache, isA<CacheClient>());
    });

    test('environment-specific behavior', () {
      // `dzIsPrd` is a compile-time constant. Tests are compiled under both
      // dev/prd by CI via `test:matrix`. Branch assertions to stay safe.
      if (dzIsPrd) {
        // In production, missing host/port should throw.
        expect(
          () => CacheFactory.create(const CacheConfig()),
          throwsArgumentError,
        );

        // With valid memorystore config, should create a MemorystoreCache instance.
        const cfg = CacheConfig(
          memorystoreHost: '127.0.0.1',
          memorystorePort: 6379,
          useTls: false,
        );
        final cache = CacheFactory.create(cfg);
        expect(cache, isA<MemorystoreCache>());
      } else {
        // In development, factory returns InMemoryCache regardless of host/port.
        const cfg = CacheConfig(
          memorystoreHost: '127.0.0.1',
          memorystorePort: 6379,
        );
        final cache = CacheFactory.create(cfg);
        expect(cache, isA<InMemoryCache>());
      }
    });
  });

  group('CacheConfig', () {
    test('constructor creates valid config', () {
      const config = CacheConfig(
        defaultTtl: Duration(minutes: 10),
        memorystoreHost: '10.0.0.3',
        memorystorePort: 6379,
      );
      expect(config.defaultTtl, equals(const Duration(minutes: 10)));
      expect(config.memorystoreHost, equals('10.0.0.3'));
      expect(config.memorystorePort, equals(6379));
      expect(config.useTls, isTrue);
    });

    test('defaults useTls to true', () {
      const config = CacheConfig(
        memorystoreHost: '10.0.0.3',
        memorystorePort: 6379,
      );
      expect(config.useTls, isTrue);
    });

    test('allows useTls to be disabled', () {
      const config = CacheConfig(
        memorystoreHost: '10.0.0.3',
        memorystorePort: 6379,
        useTls: false,
      );
      expect(config.useTls, isFalse);
    });
  });

  group('CacheErrors', () {
    test('CacheConnectionError includes message and cause', () {
      final error = CacheConnectionError(
        'Connection failed',
        cause: Exception('Network error'),
      );
      expect(error.message, equals('Connection failed'));
      expect(error.cause, isNotNull);
      expect(error.toString(), contains('Connection failed'));
      expect(error.toString(), contains('Network error'));
    });

    test('CacheSerializationError includes key', () {
      const error = CacheSerializationError('Invalid type', 'user:123');
      expect(error.message, equals('Invalid type'));
      expect(error.key, equals('user:123'));
      expect(error.toString(), contains('user:123'));
    });

    test('CacheOperationError includes operation', () {
      const error = CacheOperationError('Operation failed', 'set');
      expect(error.message, equals('Operation failed'));
      expect(error.operation, equals('set'));
      expect(error.toString(), contains('set'));
    });
  });
}
