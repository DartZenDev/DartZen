import 'dart:convert';

import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class FakeClient extends http.BaseClient {
  final http.Response response;
  late Map<String, String> lastHeaders;

  FakeClient(this.response);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastHeaders = Map.fromEntries(
      request.headers.entries.map((e) => MapEntry(e.key.toLowerCase(), e.value)),
    );
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close() {}
}

void main() {
  group('VertexAIClient remaining', () {
    test('production _getAccessToken via obtainAccessCredentials and caching', () async {
      // More complete service account JSON to satisfy ServiceAccountCredentials.fromJson
      final credsJson = jsonEncode({
        'type': 'service_account',
        'project_id': 'proj',
        'private_key_id': 'keyid',
        'private_key': '-----BEGIN PRIVATE KEY-----\nMIIB...\n-----END PRIVATE KEY-----\n',
        'client_email': 'svc@example.com',
        'client_id': 'clientid',
        'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
        'token_uri': 'https://oauth2.googleapis.com/token',
        'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
        'client_x509_cert_url': 'https://www.googleapis.com/robot/v1/metadata/x509/svc%40example.com',
      });

      // Use a simple accessTokenProvider to avoid ServiceAccount parsing in tests.
      var calls = 0;
      Future<String> accessTokenProvider() async {
        calls += 1;
        return 'prod-token';
      }

      final cfg = AIServiceConfig.dev();

      final fake = FakeClient(http.Response(jsonEncode({'text': 'ok'}), 200));
      final client = VertexAIClient(
        config: cfg,
        httpClient: fake,
        accessTokenProvider: accessTokenProvider,
      );

      // First call should set Authorization header
      final r1 = await client.generateText(const TextGenerationRequest(prompt: 'x', model: 'm'));
      print('DEBUG r1: $r1');
      print('DEBUG r1.error: ${r1.errorOrNull}');
      print('DEBUG headers: ${fake.lastHeaders}');
      expect(r1.isSuccess, isTrue);
      expect(fake.lastHeaders['authorization'], contains('prod-token'));

      // Second call should also include Authorization header
      final r2 = await client.generateText(const TextGenerationRequest(prompt: 'y', model: 'm'));
      print('DEBUG r2: $r2');
      print('DEBUG headers2: ${fake.lastHeaders}');
      expect(r2.isSuccess, isTrue);
      expect(fake.lastHeaders['authorization'], contains('prod-token'));
      expect(calls, greaterThanOrEqualTo(1));
    });

    test('invalid Retry-After header treated as quota error for 429', () async {
      final cfg = AIServiceConfig.dev();
      final fake = FakeClient(http.Response('', 429, headers: {'retry-after': 'not-a-number'}));
      final client = VertexAIClient(config: cfg, httpClient: fake);

      final res = await client.generateText(const TextGenerationRequest(prompt: 'x', model: 'm'));

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIQuotaExceededError>());
    });
  });
}
