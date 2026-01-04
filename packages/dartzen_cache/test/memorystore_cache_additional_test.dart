import 'package:dartzen_cache/src/cache_errors.dart';
import 'package:dartzen_cache/src/memorystore_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

const bool _isTest = dzIsTest;

class _RecordingTransport implements RedisTransport {
  final String Function(List<String>) responder;
  List<List<String>> calls = [];
  _RecordingTransport(this.responder);

  @override
  Future<String> sendCommand(List<String> args) async {
    calls.add(List<String>.from(args));
    return responder(args);
  }
}

void main() {
  group('MemorystoreCache additional transport tests', () {
    test('get returns null for \$-1 bulk reply', () async {
      final transport = _RecordingTransport((_) => r'$-1\r\n');
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      final v = await cache.get<String>('missing');
      expect(v, isNull);
    }, skip: !_isTest);

    test('get returns null when response has fewer than 2 lines', () async {
      final transport = _RecordingTransport((_) => '');
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      final v = await cache.get<String>('k');
      expect(v, isNull);
    }, skip: !_isTest);

    test('get throws CacheSerializationError on type mismatch', () async {
      final transport = _RecordingTransport((_) => '\$3\r\n123\r\n');
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      expect(
        () => cache.get<String>('k'),
        throwsA(isA<CacheSerializationError>()),
      );
    }, skip: !_isTest);

    test('get throws CacheOperationError on malformed JSON', () async {
      final transport = _RecordingTransport((_) => '\$13\r\n{bad json\r\n');
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      expect(
        () => cache.get<Map<String, dynamic>>('k'),
        throwsA(isA<CacheOperationError>()),
      );
    }, skip: !_isTest);

    test('delete and clear call proper commands', () async {
      final transport = _RecordingTransport((args) {
        if (args.isNotEmpty && args[0].toUpperCase() == 'DEL') {
          return ':1\\r\\n';
        }
        if (args.isNotEmpty && args[0].toUpperCase() == 'FLUSHDB') {
          return '+OK\\r\\n';
        }
        return '+OK\\r\\n';
      });

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      await cache.delete('k');
      await cache.clear();

      expect(
        transport.calls.any((c) => c.isNotEmpty && c[0].toUpperCase() == 'DEL'),
        isTrue,
      );
      expect(
        transport.calls.any(
          (c) => c.isNotEmpty && c[0].toUpperCase() == 'FLUSHDB',
        ),
        isTrue,
      );
    }, skip: !_isTest);

    test('set with ttl uses SETEX and without ttl uses SET', () async {
      final transport = _RecordingTransport((args) => '+OK\\r\\n');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      await cache.set('a', '1');
      await cache.set('b', '2', ttl: const Duration(seconds: 5));

      final setCall = transport.calls.firstWhere(
        (c) => c.isNotEmpty && c[0].toUpperCase() == 'SET',
      );
      final setexCall = transport.calls.firstWhere(
        (c) => c.isNotEmpty && c[0].toUpperCase() == 'SETEX',
      );

      expect(setCall[1], equals('a'));
      expect(setexCall[1], equals('b'));
      expect(setexCall[2], equals('5'));
    }, skip: !_isTest);

    test('transport exception surfaces CacheConnectionError', () async {
      final transport = _RecordingTransport((_) => throw Exception('boom'));
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      expect(() => cache.set('k', 'v'), throwsA(isA<CacheConnectionError>()));
    }, skip: !_isTest);
  });
}
