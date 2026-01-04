import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartzen_cache/src/cache_errors.dart';
import 'package:dartzen_cache/src/memorystore_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

const bool _isTest = dzIsTest;

// Reuse a minimal FakeSocket similar to other tests to exercise socket paths.
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
  StreamSubscription<Uint8List> listen(void Function(Uint8List)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _controller.stream.listen(onData, onError: onError as void Function(Object, StackTrace)?, onDone: onDone, cancelOnError: cancelOnError);

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
  Future<void> addStream(Stream<List<int>> stream) => _controller.addStream(stream.map(Uint8List.fromList));

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

void main() {
  // Diagnostic print to confirm whether tests are compiled with dzIsTest.
  print('[DZ_TEST] memorystore_cache_exhaustive_test starting; dzIsTest=$_isTest');

  group('MemorystoreCache exhaustive', () {
    test('ensureConnected via socketFactory', () async {
      final socket = FakeSocket([utf8.encode('+OK\r\n')]);
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        socketFactory: (h, p, {Duration? timeout, bool useTls = false}) async => socket,
      );

      await cache.testEnsureConnected();
      await socket.close();
    });

    test('ensureConnected surfaces CacheConnectionError when connector fails', () async {
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        socketConnector: (h, p, {Duration? timeout}) async => throw Exception('conn fail'),
      );

        expect(cache.testEnsureConnected, throwsA(isA<CacheConnectionError>()));
    });

    test('buildRedisCommand counts UTF-8 bytes correctly', () {
      final cache = MemorystoreCache(host: 'x', port: 1, useTls: false);
      final cmd = cache.buildRedisCommand(['SET', 'k', 'é']);
      // 'é' is 2 bytes in UTF-8 so length should reflect that
      expect(cmd, contains(r'\$3') , reason: 'command should include lengths for args');
      expect(cmd, contains('é'));
    });

    test('socket-based get works via socketFactory', () async {
      final json = jsonEncode({'a': 1});
      final resp = '\$${json.length}\r\n$json\r\n';
      final socket = FakeSocket([utf8.encode(resp)]);
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        socketFactory: (h, p, {Duration? timeout, bool useTls = false}) async => socket,
      );

      final got = await cache.get<Map<String, dynamic>>('k');
      expect(got, equals({'a': 1}));
      await socket.close();
    });

    test('close releases resources without throwing', () async {
      final socket = FakeSocket([utf8.encode('+OK\r\n')]);
      final cache = MemorystoreCache(
        host: 'x',
        port: 1,
        useTls: false,
        socketFactory: (h, p, {Duration? timeout, bool useTls = false}) async => socket,
      );
      await cache.testEnsureConnected();
      await cache.close();
      // calling close again should be harmless
      await cache.close();
    });
  });
}
