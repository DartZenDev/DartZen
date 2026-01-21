import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class FakeClient extends http.BaseClient {
  final http.Response response;
  final bool throwOnSend;
  late Map<String, String> lastHeaders;

  FakeClient(this.response, {this.throwOnSend = false});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastHeaders = Map.fromEntries(
      request.headers.entries.map(
        (e) => MapEntry(e.key.toLowerCase(), e.value),
      ),
    );
    if (throwOnSend) throw Exception('send-failure');
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
  test('returns authentication error on 401', () async {
    final cfg = AIServiceConfig.dev();
    final fake = FakeClient(http.Response('', 401));
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );

    expect(res.isFailure, true);
    expect(res.errorOrNull, isA<AIAuthenticationError>());
  });

  test('returns quota error on 429 without retry-after', () async {
    final cfg = AIServiceConfig.dev();
    final fake = FakeClient(http.Response('', 429));
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );

    expect(res.isFailure, true);
    expect(res.errorOrNull, isA<AIQuotaExceededError>());
  });

  test('honors Retry-After header on 429', () async {
    final cfg = AIServiceConfig.dev();
    final fake = FakeClient(
      http.Response('', 429, headers: {'retry-after': '3'}),
    );
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );

    expect(res.isFailure, true);
    expect(res.errorOrNull, isA<AIServiceUnavailableError>());
    final err = res.errorOrNull as AIServiceUnavailableError;
    expect(err.retryAfter?.inSeconds, 3);
  });

  test('returns invalid request on 400', () async {
    final cfg = AIServiceConfig.dev();
    final fake = FakeClient(http.Response('bad', 400));
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );

    expect(res.isFailure, true);
    expect(res.errorOrNull, isA<AIInvalidRequestError>());
    expect(
      (res.errorOrNull as AIInvalidRequestError).reason,
      contains('HTTP 400'),
    );
  });

  test('handles http exceptions as service unavailable', () async {
    final cfg = AIServiceConfig.dev();
    final fake = FakeClient(http.Response('', 200), throwOnSend: true);
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );

    expect(res.isFailure, true);
    expect(res.errorOrNull, isA<AIServiceUnavailableError>());
  });

  test('parses embeddings and usage correctly', () async {
    final cfg = AIServiceConfig.dev();
    final body = jsonEncode({
      'embeddings': [
        [1.0, 2.0],
      ],
      'requestId': 'rid',
      'usage': {'inputTokens': 1, 'outputTokens': 2},
      'metadata': {'k': 'v'},
    });
    final fake = FakeClient(http.Response(body, 200));
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.generateEmbeddings(
      const EmbeddingsRequest(texts: ['x'], model: 'm'),
    );

    expect(res.isSuccess, true);
    final data = res.dataOrNull!;
    expect(data.embeddings, hasLength(1));
    expect(data.requestId, 'rid');
    expect(data.usage?.totalTokens, 3);
    expect(data.metadata, isNotNull);
  });

  test('parses classification allScores and metadata', () async {
    final cfg = AIServiceConfig.dev();
    final body = jsonEncode({
      'label': 'spam',
      'confidence': 0.75,
      'allScores': {'a': 0.1, 'b': 0.9},
      'requestId': 'rid2',
      'usage': {'inputTokens': 2, 'outputTokens': 1},
      'metadata': {'m': 1},
    });
    final fake = FakeClient(http.Response(body, 200));
    final client = VertexAIClient(config: cfg, httpClient: fake);

    final res = await client.classify(
      const ClassificationRequest(text: 'x', model: 'm'),
    );

    expect(res.isSuccess, true);
    final data = res.dataOrNull!;
    expect(data.label, 'spam');
    expect(data.allScores, isNotNull);
    expect(data.usage?.totalTokens, 3);
    expect(data.metadata, isNotNull);
  });

  test('uses injected obtainAccessCredentials and caches token', () async {
    // Use an injected accessTokenProvider to avoid external auth parsing.
    int calls = 0;
    String? cached;
    Future<String> tokenProvider() async {
      if (cached != null) return cached!;
      calls += 1;
      cached = 'injected-token';
      return cached!;
    }

    final cfg = AIServiceConfig.dev();
    final fake = FakeClient(http.Response(jsonEncode({'text': 'ok'}), 200));
    final client = VertexAIClient(
      config: cfg,
      httpClient: fake,
      accessTokenProvider: tokenProvider,
    );

    // First call should trigger obtainAccessCredentials
    final r1 = await client.generateText(
      const TextGenerationRequest(prompt: 'x', model: 'm'),
    );

    expect(r1.isSuccess, true);
    expect(fake.lastHeaders['authorization'], 'Bearer injected-token');
    expect(calls, 1);

    // Second call should reuse cached token
    final r2 = await client.generateText(
      const TextGenerationRequest(prompt: 'y', model: 'm'),
    );

    expect(r2.isSuccess, true);
    expect(fake.lastHeaders['authorization'], 'Bearer injected-token');
    expect(calls, 1);
  });
}
