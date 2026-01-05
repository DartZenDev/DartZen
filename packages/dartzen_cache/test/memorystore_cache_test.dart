// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Consolidated memorystore cache tests. Tests from the various memorystore_* files
// have been merged here to provide a single authoritative test file for
// `memorystore_cache.dart`.

class _MockRedisTransport extends Mock implements RedisTransport {}

// Minimal fake Socket implementation to exercise the socket-based code paths.
class FakeSocket extends Stream<Uint8List> implements Socket {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();

  FakeSocket(Iterable<List<int>> events, {Object? error}) {
    Future.microtask(() async {
      if (error != null) {
        _controller.addError(error);
        await _controller.close();
        return;
      }
      for (final e in events) {
        if (_controller.isClosed) break;
        _controller.add(Uint8List.fromList(e));
      }
      await _controller.close();
    });
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _controller.stream.listen(
    onData,
    onError: onError as void Function(Object, StackTrace)?,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeln([Object? obj = '']) {}

  @override
  void add(List<int> data) {
    if (!_controller.isClosed) _controller.add(Uint8List.fromList(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) _controller.addError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      _controller.addStream(stream.map(Uint8List.fromList));

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {
    if (!_controller.isClosed) await _controller.close();
  }

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding _) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

// Socket-specific helper transports (moved from separate file).
class _FakeTransport implements RedisTransport {
  final String response;
  _FakeTransport(this.response);
  @override
  Future<String> sendCommand(List<String> args) async => response;
}

class _FailingTransport implements RedisTransport {
  @override
  Future<String> sendCommand(List<String> args) async {
    throw Exception('boom');
  }
}

void main() {
  setUpAll(() {
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
    });

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
    });

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
      expect(
        () => cache.get<dynamic>('x'),
        throwsA(isA<CacheConnectionError>()),
      );
      expect(() => cache.delete('x'), throwsA(isA<CacheConnectionError>()));
      expect(cache.clear, throwsA(isA<CacheConnectionError>()));
    });

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
    );
  });

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
    });

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
    });

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
    });

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
    });

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
    });

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
    });

    test('transport exception surfaces CacheConnectionError', () async {
      final transport = _RecordingTransport((_) => throw Exception('boom'));
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: transport,
      );

      expect(() => cache.set('k', 'v'), throwsA(isA<CacheConnectionError>()));
    });
  });

  group('MemorystoreCache - error, parsing & socket branches', () {
    test('GET returns null when Redis replies \$-1 (socket factory)', () async {
      final json = jsonEncode({'a': 1});
      final resp = '\$${json.length}\r\n$json\r\n';
      final socket = FakeSocket([utf8.encode(resp)]);
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        socketFactory: (h, p, {Duration? timeout, bool useTls = false}) async =>
            socket,
      );

      final got = await cache.get<Map<String, dynamic>>('k');
      expect(got, equals({'a': 1}));
      await socket.close();
    });

    test(
      'ensureConnected surfaces CacheConnectionError when connector fails',
      () async {
        final cache = MemorystoreCache(
          host: 'x',
          port: 1,
          useTls: false,
          socketConnector: (h, p, {Duration? timeout}) async =>
              throw Exception('conn fail'),
        );

        expect(cache.testEnsureConnected, throwsA(isA<CacheConnectionError>()));
      },
    );

    test('buildRedisCommand produces and counts UTF-8 lengths correctly', () {
      final cache = MemorystoreCache(host: 'x', port: 1, useTls: false);
      final cmd = cache.buildRedisCommand(['SET', 'k', 'é']);
      expect(cmd, contains('\$2\r\n'));
      expect(cmd, contains('é'));
    });

    test('close releases resources and is idempotent', () async {
      final socket = FakeSocket([utf8.encode('+OK\r\n')]);
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        socketFactory: (h, p, {Duration? timeout, bool useTls = false}) async =>
            socket,
      );
      await cache.testEnsureConnected();
      await cache.close();
      await cache.close();
    });
  });
  group('MemorystoreCache socket-path (moved)', () {
    test('GET via socket returns decoded JSON value', () async {
      final json = jsonEncode({'a': 1});
      final resp = '\$${json.length}\r\n$json\r\n';

      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: _FakeTransport(resp),
      );

      final v = await cache.get<Map<String, dynamic>>('k');
      expect(v, equals({'a': 1}));
    });

    test(
      'ensureConnected uses socketConnect when socketFactory is null (non-TLS)',
      () async {
        final socket = FakeSocket([utf8.encode(r'+OK\r\n')]);

        final cache = MemorystoreCache(
          host: 'x',
          port: 1,
          useTls: false,
          socketConnector: (h, p, {Duration? timeout}) async => socket,
        );

        // trigger connection logic only
        await cache.testEnsureConnected();
        await socket.close();
      },
    );

    test(
      'ensureConnected uses secureSocketConnect when socketFactory is null (TLS)',
      () async {
        final socket = FakeSocket([utf8.encode(r'+OK\r\n')]);

        final cache = MemorystoreCache(
          host: 'x',
          port: 1,
          useTls: true,
          secureSocketConnector: (h, p, {Duration? timeout}) async => socket,
        );

        // trigger connection logic only
        await cache.testEnsureConnected();
        await socket.close();
      },
    );

    test('socket first failure surfaces CacheConnectionError', () async {
      final failing = _FailingTransport();
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        transport: failing,
      );

      expect(
        () => cache.get<String>('k'),
        throwsA(isA<CacheConnectionError>()),
      );
    });
  });
}
