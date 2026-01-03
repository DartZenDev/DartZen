import 'dart:async';

import 'package:dartzen_storage/src/gcs_storage_reader.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockInnerClient extends Mock implements http.Client {}

class _BaseRequestFake extends Fake implements http.BaseRequest {}

class _FakeBaseRequest extends http.BaseRequest {
  _FakeBaseRequest(super.method, super.url, this._body);
  final List<int> _body;

  @override
  http.ByteStream finalize() {
    // call super to satisfy @mustCallSuper contract
    try {
      super.finalize();
    } catch (_) {
      // ignore; some BaseRequest implementations may throw here in test contexts
    }
    return http.ByteStream.fromBytes(_body);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_BaseRequestFake());
  });
  group('EmulatorHttpClient internals', () {
    late MockInnerClient inner;
    late EmulatorHttpClient client;

    setUp(() {
      inner = MockInnerClient();
      client = EmulatorHttpClient(inner, 'localhost:9090');
    });

    test('for http.Request copies bodyBytes and redirects host/port', () async {
      final req = http.Request('POST', Uri.parse('https://example.com/path'));
      req.bodyBytes = [1, 2, 3];

      // Capture the request passed to inner.send
      when(() => inner.send(any())).thenAnswer((invocation) async {
        final r = invocation.positionalArguments.first as http.BaseRequest;
        // Verify new URL host/port
        expect(r.url.host, equals('localhost'));
        expect(r.url.port, equals(9090));
        // bodyBytes should be copied into the new Request
        if (r is http.Request) {
          expect(r.bodyBytes, equals([1, 2, 3]));
        }
        final stream = Stream.fromIterable([<int>[]]);
        return http.StreamedResponse(stream, 200);
      });

      final streamed = await client.send(req);
      expect(streamed.statusCode, equals(200));
    });

    test('for non-Request uses finalize().bytesToString()', () async {
      final fr = _FakeBaseRequest(
        'PUT',
        Uri.parse('https://example.com/other'),
        [97, 98, 99],
      );

      when(() => inner.send(any())).thenAnswer((invocation) async {
        final r = invocation.positionalArguments.first as http.BaseRequest;
        expect(r.url.host, equals('localhost'));
        expect(r.url.port, equals(9090));
        // For non-Request, new Request.bodyBytes should equal decoded bytes
        if (r is http.Request) {
          expect(r.bodyBytes, equals([97, 98, 99]));
        }
        final stream = Stream.fromIterable([<int>[]]);
        return http.StreamedResponse(stream, 200);
      });

      final streamed = await client.send(fr);
      expect(streamed.statusCode, equals(200));
    });

    test('get delegates to send and returns StreamedResponse', () async {
      when(() => inner.send(any())).thenAnswer((_) async {
        final stream = Stream.fromIterable([<int>[]]);
        return http.StreamedResponse(stream, 204);
      });

      final resp = await client.get(Uri.parse('https://example.com/'));
      expect(resp.statusCode, equals(204));
    });
  });
}
