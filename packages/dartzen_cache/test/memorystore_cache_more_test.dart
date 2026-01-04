import 'dart:convert';

import 'package:dartzen_cache/src/cache_errors.dart';
import 'package:dartzen_cache/src/memorystore_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockTransport extends Mock implements RedisTransport {}

const bool isTest = dzIsTest;

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });


  group('MemorystoreCache - error & parsing branches', () {
    test('transport exception maps to CacheConnectionError on set', () async {
      final transport = _MockTransport();
      when(() => transport.sendCommand(any())).thenThrow(Exception('boom'));

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      expect(
        () => cache.set('k', {'a': 1}),
        throwsA(isA<CacheConnectionError>()),
      );
    }, skip: !isTest);

    test('transport exception maps to CacheConnectionError on get', () async {
      final transport = _MockTransport();
      when(() => transport.sendCommand(any())).thenThrow(Exception('boom'));

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      expect(
        () => cache.get<String>('k'),
        throwsA(isA<CacheConnectionError>()),
      );
    }, skip: !isTest);

    test('GET returns null when Redis replies \$-1', () async {
      final transport = _MockTransport();
      when(() => transport.sendCommand(any())).thenAnswer((_) async => r'$-1\r\n');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      final v = await cache.get<String>('missing');
      expect(v, isNull);
    }, skip: !isTest);

    test('malformed JSON from Redis leads to CacheOperationError', () async {
      final transport = _MockTransport();
      // RESP bulk: $13\r\n{bad json\r\n
      when(() => transport.sendCommand(any()))
          .thenAnswer((_) async => '\$13\r\n{bad json\r\n');

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
    }, skip: !isTest);

    test('set uses SET when no ttl provided', () async {
      final transport = _MockTransport();
      when(() => transport.sendCommand(any())).thenAnswer((_) async => '+OK\r\n');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      await cache.set('k', 'v');

      final verification = verify(() => transport.sendCommand(captureAny()));
      verification.called(1);
      final captured = verification.captured.first as List<String>;
      expect(captured[0], equals('SET'));
      expect(captured[1], equals('k'));
      // third argument is the JSON-encoded value
      final decoded = jsonDecode(captured[2]);
      expect(decoded, equals('v'));
    }, skip: !isTest);

    test('set uses SETEX when ttl provided', () async {
      final transport = _MockTransport();
      when(
        () => transport.sendCommand(any()),
      ).thenAnswer((_) async => '+OK\r\n');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      await cache.set('k', 'v', ttl: const Duration(seconds: 42));

      final verification = verify(() => transport.sendCommand(captureAny()));
      verification.called(1);
      final captured = verification.captured.first as List<String>;
      expect(captured[0], equals('SETEX'));
      expect(captured[1], equals('k'));
      expect(captured[2], equals('42'));
    }, skip: !isTest);

    test('set uses SETEX when defaultTtl is provided', () async {
      final transport = _MockTransport();
      when(
        () => transport.sendCommand(any()),
      ).thenAnswer((_) async => '+OK\r\n');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        defaultTtl: const Duration(seconds: 7),
        transport: transport,
      );

      await cache.set('k', 123);

      final verification = verify(() => transport.sendCommand(captureAny()));
      verification.called(1);
      final captured = verification.captured.first as List<String>;
      expect(captured[0], equals('SETEX'));
      expect(captured[1], equals('k'));
      expect(captured[2], equals('7'));
    }, skip: !isTest);

    test('get throws CacheSerializationError on type mismatch', () async {
      final transport = _MockTransport();
      // Return bulk with JSON number 123
      when(
        () => transport.sendCommand(any()),
      ).thenAnswer((_) async => '\$3\r\n123\r\n');

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
    }, skip: !isTest);

    test(
      'set throws CacheSerializationError for non-serializable value',
      () async {
        final transport = _MockTransport();
        when(
          () => transport.sendCommand(any()),
        ).thenAnswer((_) async => '+OK\r\n');

        final cache = MemorystoreCache(
          host: 'x',
          port: 1,
          useTls: false,
          transport: transport,
        );

        // Functions are not json-serializable
        expect(
          () => cache.set('k', () => 'nope'),
          throwsA(isA<CacheSerializationError>()),
        );
      },
      skip: !isTest,
    );

    test('get returns null when response has fewer than 2 lines', () async {
      final transport = _MockTransport();
      when(
        () => transport.sendCommand(any()),
      ).thenAnswer((_) async => '');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      final v = await cache.get<String>('k');
      expect(v, isNull);
    }, skip: !isTest);

    test('buildRedisCommand produces expected RESP string', () {
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
      );

      final cmd = cache.buildRedisCommand(['SET', 'k', 'v']);
      expect(cmd, equals('*3\r\n\$3\r\nSET\r\n\$1\r\nk\r\n\$1\r\nv\r\n'));
    }, skip: !isTest);

    test('close is idempotent and sets internal state', () async {
      final transport = _MockTransport();
      when(() => transport.sendCommand(any())).thenAnswer((_) async => '+OK\r\n');

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      // calling close when nothing is connected should not throw
      await cache.close();
      await cache.close();
    }, skip: !isTest);

    test('buildRedisCommand counts UTF-8 bytes correctly', () {
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
      );

      // 'é' is 2 bytes in UTF-8
      final cmd = cache.buildRedisCommand(['SET', 'k', 'é']);
      expect(cmd.contains('\$2\r\n'), isTrue);
    }, skip: !isTest);
  });
}
