import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

const bool isTest = dzIsTest;

class _MockRedisTransport extends Mock implements RedisTransport {}

void main() {
  setUpAll(() {
    // Register fallback for List<String> used as an argument to sendCommand
    registerFallbackValue(<String>[]);
  });

  group('MemorystoreCache (mock transport)', () {
    late _MockRedisTransport mock;

    setUp(() {
      mock = _MockRedisTransport();
    });

    test('set/get/delete/clear via transport', () async {
      final Map<String, String> store = {};

      when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
        final args = inv.positionalArguments[0] as List<String>;
        final cmd = args.isNotEmpty ? args[0].toUpperCase() : '';
        if (cmd == 'SET' && args.length >= 3) {
          store[args[1]] = args[2];
          return '+OK\r\n';
        }
        if (cmd == 'SETEX' && args.length >= 4) {
          store[args[1]] = args[3];
          return '+OK\r\n';
        }
        if (cmd == 'GET' && args.length >= 2) {
          final key = args[1];
          final val = store[key];
          if (val == null) return r'$-1\r\n';
          return '\$${val.length}\r\n$val\r\n';
        }
        if (cmd == 'DEL' && args.length >= 2) {
          final removed = store.remove(args[1]) != null ? 1 : 0;
          return ':$removed\r\n';
        }
        if (cmd == 'FLUSHDB') {
          store.clear();
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

      await cache.set('k', {'v': 1});
      final v = await cache.get<Map<String, dynamic>>('k');
      expect(v, equals({'v': 1}));

      await cache.delete('k');
      expect(await cache.get<dynamic>('k'), isNull);

      await cache.set('a', '1');
      await cache.clear();
      expect(await cache.get<dynamic>('a'), isNull);
    }, skip: !isTest);

    test('serialization mismatch throws', () async {
      final Map<String, String> store = {};
      when(() => mock.sendCommand(any<List<String>>())).thenAnswer((inv) async {
        final args = inv.positionalArguments[0] as List<String>;
        final cmd = args.isNotEmpty ? args[0].toUpperCase() : '';
        if (cmd == 'SET' && args.length >= 3) {
          store[args[1]] = args[2];
          return '+OK\r\n';
        }
        if (cmd == 'GET') {
          final key = args[1];
          final val = store[key] ?? '"123"';
          return '\$${val.length}\r\n$val\r\n';
        }
        return '+OK\r\n';
      });

      final cache = MemorystoreCache(
        host: 'fake',
        port: 1,
        useTls: false,
        transport: mock,
      );

      // stored string "123" cannot be deserialized to int
      await mock.sendCommand(['SET', 'k', '"123"']);
      expect(
        () => cache.get<int>('k'),
        throwsA(isA<CacheSerializationError>()),
      );
    }, skip: !isTest);

    test('transport failure surfaces CacheConnectionError', () async {
      when(
        () => mock.sendCommand(any<List<String>>()),
      ).thenThrow(Exception('network'));

      final cache = MemorystoreCache(
        host: 'fake',
        port: 1,
        useTls: false,
        transport: mock,
      );

      expect(() => cache.set('x', '1'), throwsA(isA<CacheConnectionError>()));
      expect(() => cache.get<dynamic>('x'), throwsA(isA<CacheConnectionError>()));
      expect(() => cache.delete('x'), throwsA(isA<CacheConnectionError>()));
      expect(cache.clear, throwsA(isA<CacheConnectionError>()));
    }, skip: !isTest);

    test(
      'set with non-serializable value throws CacheSerializationError',
      () async {
        // transport should not be called because jsonEncode fails first
        when(
          () => mock.sendCommand(any<List<String>>()),
        ).thenAnswer((_) async => '+OK\r\n');

        final cache = MemorystoreCache(
          host: 'fake',
          port: 1,
          useTls: false,
          transport: mock,
        );

        expect(
          () => cache.set('k', () => 'fn'),
          throwsA(isA<CacheSerializationError>()),
        );
      },
        skip: !isTest,
    );
  });
}
