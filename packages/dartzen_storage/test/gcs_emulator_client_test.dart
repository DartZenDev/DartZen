import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_storage/src/gcs_storage_reader.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockClient extends Mock implements http.Client {}

class _FakeBaseRequest extends http.BaseRequest {
  _FakeBaseRequest(super.method, super.url, Stream<List<int>> stream)
    : _stream = stream;

  final Stream<List<int>> _stream;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_stream);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(http.Request('GET', Uri.parse('http://example.com')));
  });

  group('EmulatorHttpClient', () {
    late MockClient inner;
    late EmulatorHttpClient client;

    setUp(() {
      inner = MockClient();
      client = EmulatorHttpClient(inner, 'localhost:8080');
    });

    test('rewrites request URL and preserves headers', () async {
      when(() => inner.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.fromIterable([utf8.encode('ok')]),
          200,
        ),
      );

      final req = http.Request(
        'GET',
        Uri.parse('https://storage.googleapis.com/bucket/object'),
      );
      req.headers['x-custom'] = '1';

      final streamed = await client.send(req);
      expect(streamed.statusCode, equals(200));

      final captured = verify(() => inner.send(captureAny())).captured;
      expect(captured, isNotEmpty);
      final sent = captured.first as http.BaseRequest;
      expect(sent.url.scheme, equals('http'));
      expect(sent.url.host, equals('localhost'));
      expect(sent.url.port, equals(8080));
      expect(sent.headers['x-custom'], equals('1'));
    });

    test('copies body from non-Request finalize stream', () async {
      when(() => inner.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.fromIterable([utf8.encode('ok')]),
          200,
        ),
      );

      final stream = Stream<List<int>>.fromIterable([
        Uint8List.fromList([1, 2]),
        Uint8List.fromList([3]),
      ]);

      final fake = _FakeBaseRequest(
        'POST',
        Uri.parse('https://storage.googleapis.com/bucket/upload'),
        stream,
      );
      fake.headers['content-type'] = 'application/octet-stream';

      final resp = await client.send(fake);
      expect(resp.statusCode, equals(200));

      final captured = verify(() => inner.send(captureAny())).captured;
      expect(captured, isNotEmpty);
      final sent = captured.first as http.Request;
      expect(sent.bodyBytes, equals([1, 2, 3]));
      expect(sent.headers['content-type'], equals('application/octet-stream'));
    });
  });
}
