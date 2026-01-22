import 'dart:convert';

import 'package:dartzen_payments/src/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('parses empty body as no-data', () async {
    final client = DefaultPaymentsHttpClient(
      baseUrl: 'https://example.com',
      client: MockClient(
        (r) async => http.Response('', 204, headers: {'x-request-id': 'rid'}),
      ),
    );

    final resp = await client.post('/x', null);
    expect(resp.id, equals('rid'));
    expect(resp.statusCode, equals(204));
    expect(resp.data, isNull);
    client.close();
  });

  test('parses json map and error field', () async {
    final body = jsonEncode({'ok': true, 'error': 'bad'});
    final client = DefaultPaymentsHttpClient(
      baseUrl: 'https://example.com',
      client: MockClient((r) async => http.Response(body, 400, headers: {})),
    );

    final resp = await client.post('/x', {'a': 1});
    expect(resp.statusCode, equals(400));
    expect(resp.data, isA<Map<String, dynamic>>());
    final data = resp.data as Map<String, dynamic>;
    expect(data['ok'], isTrue);
    expect(resp.error, equals('bad'));
    client.close();
  });

  test('invalid json body is ignored', () async {
    final client = DefaultPaymentsHttpClient(
      baseUrl: 'https://example.com',
      client: MockClient((r) async => http.Response('not-json', 200)),
    );

    final resp = await client.post('/x', null);
    // invalid body -> parsed data null
    expect(resp.data, isNull);
    client.close();
  });
}
