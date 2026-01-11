import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class SpyClient extends http.BaseClient {
  final http.Client _inner;
  late Map<String, String> lastHeaders;
  final http.Response response;

  SpyClient(this.response) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastHeaders = Map.fromEntries(
      request.headers.entries.map(
        (e) => MapEntry(e.key.toLowerCase(), e.value),
      ),
    );
    final streamed = http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
    return streamed;
  }

  @override
  void close() => _inner.close();
}

void main() {
  test('dev mode uses mock token in Authorization header', () async {
    final config = AIServiceConfig.dev();
    final spyResponse = http.Response(jsonEncode({'text': 'ok'}), 200);
    final spyClient = SpyClient(spyResponse);

    final client = VertexAIClient(config: config, httpClient: spyClient);

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );
    expect(res.isSuccess, true);
    expect(spyClient.lastHeaders['authorization'], 'Bearer mock-access-token');
  });

  test('custom accessTokenProvider is used when provided', () async {
    final config = AIServiceConfig.dev();
    final spyResponse = http.Response(jsonEncode({'text': 'ok'}), 200);
    final spyClient = SpyClient(spyResponse);

    final client = VertexAIClient(
      config: config,
      httpClient: spyClient,
      accessTokenProvider: () async => 'injected-token',
    );

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );
    expect(res.isSuccess, true);
    expect(spyClient.lastHeaders['authorization'], 'Bearer injected-token');
  });

  // Service-account auth tests are environment-dependent and require valid
  // service account JSON. The client supports injecting
  // `obtainAccessCredentials` for integration testing; authentication
  // rotation is covered by integration tests outside unit tests.
}
