import 'dart:convert';

import 'package:dartzen_ai/src/client/http_transport.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this._response);
  final http.Response _response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = _response.bodyBytes;
    final stream = Stream.value(bytes);
    return http.StreamedResponse(
      stream,
      _response.statusCode,
      headers: _response.headers,
      request: request,
    );
  }

  @override
  void close() {}
}

void main() {
  group('DefaultAIHttpClient', () {
    test('parses empty body as null data', () async {
      final client = DefaultAIHttpClient(
        baseUrl: 'https://example.com',
        client: _FakeClient(http.Response('', 200)),
      );

      final resp = await client.post('/foo', null);

      expect(resp.data, isNull);
      expect(resp.error, isNull);
    });

    test('parses JSON object with error field', () async {
      final body = jsonEncode({'error': 'bad', 'x': 1});
      final client = DefaultAIHttpClient(
        baseUrl: 'https://example.com',
        client: _FakeClient(http.Response(body, 200)),
      );

      final resp = await client.post('/foo', null);

      expect(resp.data, isA<Map<String, dynamic>>());
      expect(resp.error, equals('bad'));
    });

    test('parses JSON array as data', () async {
      final body = jsonEncode([1, 2, 3]);
      final client = DefaultAIHttpClient(
        baseUrl: 'https://example.com',
        client: _FakeClient(http.Response(body, 200)),
      );

      final resp = await client.post('/foo', null);

      expect(resp.data, isA<List<dynamic>>());
      expect(resp.error, isNull);
    });

    test('non-200 returns parsed response when body not JSON', () async {
      final client = DefaultAIHttpClient(
        baseUrl: 'https://example.com',
        client: _FakeClient(http.Response('oops', 400)),
      );

      final resp = await client.post('/foo', null);

      expect(resp.status, equals(400));
      expect(resp.data, isNull);
    });
  });
}
