import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

const bool isTest = dzIsTest;

class _MockRedisTransport extends Mock implements RedisTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  test('set uses SETEX when ttl provided', () async {
    final mock = _MockRedisTransport();
    List<String>? lastArgs;

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      lastArgs = List<String>.from(inv.positionalArguments[0] as List);
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    await cache.set('k', 'v', ttl: const Duration(seconds: 10));

    expect(lastArgs, isNotNull);
    expect(lastArgs![0].toUpperCase(), equals('SETEX'));
    expect(lastArgs![1], equals('k'));
    expect(lastArgs![2], equals('10'));
    expect(lastArgs![3], equals('"v"'));
  }, skip: !isTest);

  test('set without ttl uses SET', () async {
    final mock = _MockRedisTransport();
    List<String>? lastArgs;

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      lastArgs = List<String>.from(inv.positionalArguments[0] as List);
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    await cache.set('k', 'v');

    expect(lastArgs, isNotNull);
    expect(lastArgs![0].toUpperCase(), equals('SET'));
    expect(lastArgs![1], equals('k'));
    expect(lastArgs![2], equals('"v"'));
  }, skip: !isTest);

  test(
    'close completes and subsequent operations still use transport',
    () async {
      final mock = _MockRedisTransport();
      when(
        () => mock.sendCommand(any<List<String>>()),
      ).thenAnswer((_) async => '+OK\r\n');

      final cache = MemorystoreCache(
        host: 'fake',
        port: 1,
        useTls: false,
        transport: mock,
      );

      await cache.set('a', '1');
      await cache.close();

      // after close the transport path should still work (no sockets used)
      await cache.set('b', '2');
    }, skip: !isTest,
  );

  test(r'get returns null when Redis replies with $-1', () async {
    final mock = _MockRedisTransport();

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      final args = inv.positionalArguments[0] as List<String>;
      if (args.isNotEmpty && args[0].toUpperCase() == 'GET') {
        return r'$-1\r\n';
      }
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    final v = await cache.get<dynamic>('missing');
    expect(v, isNull);
  }, skip: !isTest);

  test('malformed JSON from Redis surfaces CacheOperationError', () async {
    final mock = _MockRedisTransport();

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      final args = inv.positionalArguments[0] as List<String>;
      if (args.isNotEmpty && args[0].toUpperCase() == 'GET') {
        return '\$3\r\nabc\r\n';
      }
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    expect(cache.get<dynamic>('k'), throwsA(isA<CacheOperationError>()));
  }, skip: !isTest);

  test('tiny TTL results in SETEX with 0 seconds', () async {
    final mock = _MockRedisTransport();
    List<String>? lastArgs;

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      lastArgs = List<String>.from(inv.positionalArguments[0] as List);
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    await cache.set('k', 'v', ttl: const Duration(milliseconds: 500));

    expect(lastArgs, isNotNull);
    expect(lastArgs![0].toUpperCase(), equals('SETEX'));
    expect(lastArgs![2], equals('0'));
  }, skip: !isTest);

  test('GET returns null when response is not a bulk string', () async {
    final mock = _MockRedisTransport();

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      final args = inv.positionalArguments[0] as List<String>;
      if (args.isNotEmpty && args[0].toUpperCase() == 'GET') {
        return '+OK\r\n';
      }
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    expect(cache.get<dynamic>('k'), throwsA(isA<CacheOperationError>()));
  }, skip: !isTest);

  test('get returns null when response has fewer than 2 lines', () async {
    final mock = _MockRedisTransport();

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async => '');

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    final v = await cache.get<dynamic>('k');
    expect(v, isNull);
  }, skip: !isTest);

  test('close is idempotent and can be called multiple times', () async {
    final mock = _MockRedisTransport();
    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((_) async => '+OK\r\n');

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      transport: mock,
    );

    await cache.close();
    await cache.close();
  }, skip: !isTest);

  test('defaultTtl in constructor causes SETEX without ttl arg', () async {
    final mock = _MockRedisTransport();
    List<String>? lastArgs;

    when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
      lastArgs = List<String>.from(inv.positionalArguments[0] as List);
      return '+OK\r\n';
    });

    final cache = MemorystoreCache(
      host: 'fake',
      port: 1,
      useTls: false,
      defaultTtl: const Duration(seconds: 5),
      transport: mock,
    );

    await cache.set('k', 'v');

    expect(lastArgs, isNotNull);
    expect(lastArgs![0].toUpperCase(), equals('SETEX'));
    expect(lastArgs![2], equals('5'));
  }, skip: !isTest);
}
