import 'dart:convert';

import 'package:dartzen_cache/src/cache_errors.dart';
import 'package:dartzen_cache/src/memorystore_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

const bool _isTest = dzIsTest;

class _RecordingTransport implements RedisTransport {
  List<String>? lastArgs;
  final String response;
  _RecordingTransport({this.response = '+OK\r\n'});
  @override
  Future<String> sendCommand(List<String> args) async {
    lastArgs = List<String>.from(args);
    return response;
  }
}

void main() {
  group('MemorystoreCache focused', () {
    test('buildRedisCommand formats RESP correctly', () {
      if (!_isTest) return;
      final cache = MemorystoreCache(host: 'x', port: 1, useTls: false);
      final cmd = cache.buildRedisCommand(['SET', 'k', 'v']);
      expect(cmd, equals('*3\r\n\$3\r\nSET\r\n\$1\r\nk\r\n\$1\r\nv\r\n'));
    }, skip: !_isTest);

    test(
      'set with TTL uses SETEX with seconds and JSON encoded value',
      () async {
        if (!_isTest) return;
        final recorder = _RecordingTransport();
        final cache = MemorystoreCache(
          host: 'x',
          port: 1,
          useTls: false,
          transport: recorder,
        );

        await cache.set('mykey', {'a': 1}, ttl: const Duration(seconds: 5));
        expect(
          recorder.lastArgs,
          equals([
            'SETEX',
            'mykey',
            '5',
            jsonEncode({'a': 1}),
          ]),
        );
      },
      skip: !_isTest,
    );

    test('set without TTL uses SET', () async {
      if (!_isTest) return;
      final recorder = _RecordingTransport();
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: recorder,
      );

      await cache.set('k', 'v');
      expect(recorder.lastArgs, equals(['SET', 'k', jsonEncode('v')]));
    }, skip: !_isTest);

    test('get returns null for \$-1 reply', () async {
      if (!_isTest) return;
      final transport = _RecordingTransport(response: '\$-1\r\n');
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
      if (!_isTest) return;
      // store a number but request String
      const json = '123';
      const resp = '\$${json.length}\r\n$json\r\n';
      final transport = _RecordingTransport(response: resp);
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

    test('delete issues DEL command', () async {
      if (!_isTest) return;
      final recorder = _RecordingTransport();
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: recorder,
      );

      await cache.delete('k');
      expect(recorder.lastArgs, equals(['DEL', 'k']));
    }, skip: !_isTest);

    test('clear issues FLUSHDB command', () async {
      if (!_isTest) return;
      final recorder = _RecordingTransport();
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: recorder,
      );

      await cache.clear();
      expect(recorder.lastArgs, equals(['FLUSHDB']));
    }, skip: !_isTest);

    test(
      'set throws CacheSerializationError for non-serializable value',
      () async {
        if (!_isTest) return;
        final recorder = _RecordingTransport();
        final cache = MemorystoreCache(
          host: 'x',
          port: 1,
          useTls: false,
          transport: recorder,
        );

        expect(
          () => cache.set('k', Object()),
          throwsA(isA<CacheSerializationError>()),
        );
      },
      skip: !_isTest,
    );

    test('transport throwing maps to CacheConnectionError for set', () async {
      if (!_isTest) return;
      final failing = _RecordingTransport();
      // Replace sendCommand to throw
      failing.lastArgs = null;
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: _ThrowingTransport(),
      );

      expect(() => cache.set('k', 'v'), throwsA(isA<CacheConnectionError>()));
    }, skip: !_isTest);
  });
}

class _ThrowingTransport implements RedisTransport {
  @override
  Future<String> sendCommand(List<String> args) async =>
      throw Exception('transport fail');
}
