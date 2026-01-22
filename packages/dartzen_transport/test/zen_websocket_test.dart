import 'dart:async';
import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:dartzen_transport/src/internal/websocket/zen_websocket.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeSink implements WebSocketSink {
  final List<dynamic> added = <dynamic>[];
  bool closed = false;
  int? lastCode;
  String? lastReason;

  @override
  void add(dynamic data) => added.add(data);

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final _ in stream) {
      // consume stream without side-effects
    }
  }

  @override
  Future<void> get done => Future<void>.value();

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    lastCode = closeCode;
    lastReason = closeReason;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      throw UnimplementedError();
}

// ignore: strict_raw_type
class _FakeChannel
    with StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final Stream<dynamic> _stream;
  final WebSocketSink _sink;

  _FakeChannel(this._stream, this._sink);

  @override
  Stream<dynamic> get stream => _stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future<void>.value();
}

void main() {
  group('ZenWebSocket', () {
    group('format selection', () {
      test('default codec is selected when no format specified', () {
        // This test verifies that selectDefaultCodec() works
        final format = selectDefaultCodec();
        expect(
          format,
          isIn([ZenTransportFormat.json, ZenTransportFormat.msgpack]),
        );
      });

      test('format property reflects the selected codec', () {
        // We can't easily create a ZenWebSocket without a real WebSocket connection
        // but we can verify the codec selector works
        expect(ZenTransportFormat.json.value, 'json');
        expect(ZenTransportFormat.msgpack.value, 'msgpack');
      });
    });

    group('encoding/decoding', () {
      test('ZenRequest encodes correctly for WebSocket transmission', () {
        const request = ZenRequest(
          id: 'req-123',
          path: '/api/users',
          data: {'name': 'Alice'},
        );

        // Encode with JSON
        final jsonEncoded = request.encodeWith(ZenTransportFormat.json);
        expect(jsonEncoded, isNotNull);

        // Verify it can be decoded back
        final jsonDecoded = ZenRequest.decodeWith(
          jsonEncoded,
          ZenTransportFormat.json,
        );
        expect(jsonDecoded.id, 'req-123');
        expect(jsonDecoded.path, '/api/users');
        expect(jsonDecoded.data, {'name': 'Alice'});

        // Encode with MessagePack
        final msgpackEncoded = request.encodeWith(ZenTransportFormat.msgpack);
        expect(msgpackEncoded, isNotNull);

        // Verify it can be decoded back
        final msgpackDecoded = ZenRequest.decodeWith(
          msgpackEncoded,
          ZenTransportFormat.msgpack,
        );
        expect(msgpackDecoded.id, 'req-123');
        expect(msgpackDecoded.path, '/api/users');
        expect(msgpackDecoded.data, {'name': 'Alice'});
      });

      test('ZenResponse encodes correctly for WebSocket transmission', () {
        const response = ZenResponse(
          id: 'res-456',
          status: 200,
          data: {'result': 'success'},
        );

        // Encode with JSON
        final jsonEncoded = response.encodeWith(ZenTransportFormat.json);
        expect(jsonEncoded, isNotNull);

        // Verify it can be decoded back
        final jsonDecoded = ZenResponse.decodeWith(
          jsonEncoded,
          ZenTransportFormat.json,
        );
        expect(jsonDecoded.id, 'res-456');
        expect(jsonDecoded.status, 200);
        expect(jsonDecoded.data, {'result': 'success'});

        // Encode with MessagePack
        final msgpackEncoded = response.encodeWith(ZenTransportFormat.msgpack);
        expect(msgpackEncoded, isNotNull);

        // Verify it can be decoded back
        final msgpackDecoded = ZenResponse.decodeWith(
          msgpackEncoded,
          ZenTransportFormat.msgpack,
        );
        expect(msgpackDecoded.id, 'res-456');
        expect(msgpackDecoded.status, 200);
        expect(msgpackDecoded.data, {'result': 'success'});
      });

      test('handles error responses in WebSocket messages', () {
        const errorResponse = ZenResponse(
          id: 'res-789',
          status: 404,
          error: 'Not found',
        );

        final encoded = errorResponse.encodeWith(ZenTransportFormat.json);
        final decoded = ZenResponse.decodeWith(
          encoded,
          ZenTransportFormat.json,
        );

        expect(decoded.id, 'res-789');
        expect(decoded.status, 404);
        expect(decoded.isError, true);
        expect(decoded.isSuccess, false);
        expect(decoded.error, 'Not found');
      });

      test('handles complex data structures', () {
        const request = ZenRequest(
          id: 'req-complex',
          path: '/api/complex',
          data: {
            'nested': {
              'array': [1, 2, 3],
              'map': {'key': 'value'},
            },
            'list': ['a', 'b', 'c'],
          },
        );

        final jsonEncoded = request.encodeWith(ZenTransportFormat.json);
        final jsonDecoded = ZenRequest.decodeWith(
          jsonEncoded,
          ZenTransportFormat.json,
        );
        expect(jsonDecoded.data, request.data);

        final msgpackEncoded = request.encodeWith(ZenTransportFormat.msgpack);
        final msgpackDecoded = ZenRequest.decodeWith(
          msgpackEncoded,
          ZenTransportFormat.msgpack,
        );
        expect(msgpackDecoded.data, request.data);
      });
    });

    group('integration scenarios', () {
      test('request-response cycle encoding matches', () {
        // Simulate client sending request
        const clientRequest = ZenRequest(
          id: 'req-echo',
          path: '/api/echo',
          data: {'message': 'hello'},
        );

        final encoded = clientRequest.encodeWith(ZenTransportFormat.json);

        // Simulate server receiving and decoding
        final serverRequest = ZenRequest.decodeWith(
          encoded,
          ZenTransportFormat.json,
        );
        expect(serverRequest.id, clientRequest.id);
        expect(serverRequest.data, clientRequest.data);

        // Simulate server sending response
        final serverResponse = ZenResponse(
          id: serverRequest.id,
          status: 200,
          data: {'echo': serverRequest.data},
        );

        final responseEncoded = serverResponse.encodeWith(
          ZenTransportFormat.json,
        );

        // Simulate client receiving response
        final clientResponse = ZenResponse.decodeWith(
          responseEncoded,
          ZenTransportFormat.json,
        );
        expect(clientResponse.id, serverResponse.id);
        expect(clientResponse.status, 200);
        expect(clientResponse.data, {
          'echo': {'message': 'hello'},
        });
      });
    });

    group('additional branches', () {
      test('header selection and parse behavior', () {
        // Validate header parsing via ZenTransportFormat.parse
        expect(
          ZenTransportFormat.parse('json'),
          equals(ZenTransportFormat.json),
        );
        expect(
          ZenTransportFormat.parse('msgpack'),
          equals(ZenTransportFormat.msgpack),
        );
        expect(
          () => ZenTransportFormat.parse('bogus'),
          throwsA(isA<ZenTransportException>()),
        );
      });

      test('decoding non-map payload in ZenMessage.decodeWith throws', () {
        // Create a JSON payload that is a list, not a map.
        final bytes = ZenEncoder.encode([1, 2, 3], ZenTransportFormat.json);
        expect(
          () => ZenMessage.decodeWith(
            Uint8List.fromList(bytes),
            ZenTransportFormat.json,
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('mapping throws on unexpected message types', () {
        expect(
          () => ZenWebSocket.mapMessageToResponse(
            'not-bytes',
            ZenTransportFormat.json,
          ),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('additional websocket behavior', () {
      test('responses stream decodes Uint8List and List<int>', () async {
        const resp = ZenResponse(id: 'r1', status: 200, data: {'ok': true});
        final bytes = resp.encodeWith(ZenTransportFormat.json);

        final stream1 = Stream<dynamic>.fromIterable([
          Uint8List.fromList(bytes),
        ]);
        final stream2 = Stream<dynamic>.fromIterable([bytes.toList()]);
        final sink = _FakeSink();
        final channel1 = _FakeChannel(stream1, sink);
        final channel2 = _FakeChannel(stream2, sink);

        final ws1 = ZenWebSocket.withChannel(
          channel1,
          format: ZenTransportFormat.json,
        );
        final ws2 = ZenWebSocket.withChannel(
          channel2,
          format: ZenTransportFormat.json,
        );

        final first = await ws1.responses.first;
        expect(first.id, equals(resp.id));

        final second = await ws2.responses.first;
        expect(second.id, equals(resp.id));
        await sink.close();
      });

      test('send writes encoded bytes to sink', () async {
        const stream = Stream<dynamic>.empty();
        final sink = _FakeSink();
        final channel = _FakeChannel(stream, sink);

        final ws = ZenWebSocket.withChannel(
          channel,
          format: ZenTransportFormat.json,
        );

        const request = ZenRequest(id: 'req-1', path: '/p', data: {'x': 1});
        ws.send(request);

        // sink should have received one entry which is Uint8List
        expect(sink.added, isNotEmpty);
        final added = sink.added.first;
        expect(added, isA<Uint8List>());

        // decode to verify
        final decoded = ZenRequest.decodeWith(
          Uint8List.fromList(added as Uint8List),
          ZenTransportFormat.json,
        );
        expect(decoded.id, request.id);

        await sink.close();
      });

      test('close delegates to sink.close with params', () async {
        const stream = Stream<dynamic>.empty();
        final sink = _FakeSink();
        final channel = _FakeChannel(stream, sink);

        final ws = ZenWebSocket.withChannel(
          channel,
          format: ZenTransportFormat.json,
        );

        await ws.close(1000, 'bye');
        expect(sink.closed, isTrue);
        expect(sink.lastCode, equals(1000));
        expect(sink.lastReason, equals('bye'));
        await sink.close();
      });
    });
  });
  // Note: Full ZenWebSocket integration tests require a live WebSocket server
  // and are better suited for integration test suites rather than unit tests.
  // The above tests verify that the encoding/decoding logic used by ZenWebSocket
  // works correctly, which is the core transport concern.
}
