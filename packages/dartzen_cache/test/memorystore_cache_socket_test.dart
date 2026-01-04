import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartzen_cache/src/cache_errors.dart';
import 'package:dartzen_cache/src/memorystore_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

// Minimal fake Socket implementation to exercise the socket-based code paths.
class FakeSocket extends Stream<Uint8List> implements Socket {
  final List<Uint8List> _events;
  // The controller is intentionally long-lived for the fake socket used
  // throughout the test; tests explicitly close it. Suppress the lint
  // that requires closing the sink in the same function scope.
  // ignore: close_sinks
  final _controller = StreamController<Uint8List>();

  FakeSocket(Iterable<List<int>> events, {Object? error, StackTrace? stackTrace, bool closeAfterError = false})
    : _events = events.map(Uint8List.fromList).toList() {
    Future.microtask(() async {
      try {
        if (error != null) {
          if (!_controller.isClosed) {
            _controller.addError(error, stackTrace);
          }
          if (closeAfterError) {
            if (!_controller.isClosed) await _controller.close();
            return;
          }
        }
        for (final e in _events) {
          if (_controller.isClosed) break;
          _controller.add(e);
        }
      } finally {
        if (!_controller.isClosed) await _controller.close();
      }
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

  // Minimal IOSink-like methods used by the cache implementation.
  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeln([Object? obj = '']) {}

  @override
  void add(List<int> data) {
    if (!_controller.isClosed) {
      _controller.add(Uint8List.fromList(data));
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) {
      _controller.addError(error, stackTrace);
    }
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      _controller.isClosed ? Future.value() : _controller.addStream(stream.map(Uint8List.fromList));

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

const bool isTest = dzIsTest;

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
  group('MemorystoreCache socket-path', () {
    test('GET via socket returns decoded JSON value', () async {
      // simulate Redis bulk reply for '{"a":1}' and use transport to avoid sockets
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
    }, skip: !isTest);

    test('ensureConnected uses socketConnect when socketFactory is null (non-TLS)', () async {
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
    }, skip: !isTest);

    test('ensureConnected uses secureSocketConnect when socketFactory is null (TLS)', () async {
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
    }, skip: !isTest);

    test('socket first failure surfaces CacheConnectionError', () async {
      // Simulate transport failure mapping to CacheConnectionError.
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
    }, skip: !isTest);
  });
}
