import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_ai/src/client/http_transport.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this._response);

  final http.Response _response;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastHeaders = request.headers;
    // extract body if present
    if (request is http.Request) {
      lastBody = request.body;
    }
    final bytes = utf8.encode(_response.body);
    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(bytes)),
      _response.statusCode,
      headers: _response.headers,
      request: request,
    );
  }

  @override
  void close() {}
}

void main() {
  group('DefaultAIHttpClient parsing', () {
    test('empty body returns empty parsed data', () async {
      final fake = _FakeClient(
        http.Response('', 200, headers: {'x-request-id': 'rid-1'}),
      );
      final client = DefaultAIHttpClient(
        baseUrl: 'https://example.com/',
        client: fake,
      );

      final res = await client.post('/v1/test', null);

      expect(res.status, equals(200));
      expect(res.id, equals('rid-1'));
      expect(res.data, isNull);
      expect(res.error, isNull);
    });

    test('json map body with error field returns error', () async {
      final body = jsonEncode({'error': 'bad', 'detail': 1});
      final fake = _FakeClient(
        http.Response(body, 400, headers: {'x-request-id': 'rid-2'}),
      );
      final client = DefaultAIHttpClient(baseUrl: 'https://api/', client: fake);

      final res = await client.post(
        'path',
        {'a': 1},
        headers: {'x-custom': 'v'},
      );

      expect(res.status, equals(400));
      expect(res.id, equals('rid-2'));
      expect(res.data, isA<Map<String, dynamic>>());
      expect(res.error, equals('bad'));

      // verify headers merged
      expect(fake.lastHeaders?['x-custom'], equals('v'));
      expect(fake.lastHeaders?['content-type'], equals('application/json'));
      expect(fake.lastBody, isNotNull);
    });

    test('json array body returns list data', () async {
      final body = jsonEncode([1, 2, 3]);
      final fake = _FakeClient(http.Response(body, 200));
      final client = DefaultAIHttpClient(
        baseUrl: 'https://host/',
        client: fake,
      );

      final res = await client.post('/arr', {});

      expect(res.status, equals(200));
      expect(res.data, isA<List<dynamic>>());
      expect(res.error, isNull);
    });

    test('invalid json body returns empty parsed', () async {
      final fake = _FakeClient(http.Response('not-json', 200));
      final client = DefaultAIHttpClient(
        baseUrl: 'https://host/',
        client: fake,
      );

      final res = await client.post('/bad', {'x': 'y'});

      expect(res.status, equals(200));
      expect(res.data, isNull);
      expect(res.error, isNull);
    });

    test('missing x-request-id generates id', () async {
      final fake = _FakeClient(http.Response(jsonEncode({'ok': true}), 200));
      final client = DefaultAIHttpClient(
        baseUrl: 'https://host/',
        client: fake,
      );

      final res = await client.post('/', null);

      expect(res.status, equals(200));
      expect(res.id, isNotEmpty);
    });
  });
}
