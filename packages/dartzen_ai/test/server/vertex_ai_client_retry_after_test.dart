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
      request.headers.entries.map((e) => MapEntry(e.key.toLowerCase(), e.value)),
    );
    if (throwOnSend) throw Exception('send-failure');
    return http.StreamedResponse(
      Stream.value(const Utf8Encoder().convert(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close() {}
}

void main() {
  group('VertexAIClient Retry-After HTTP-date handling', () {
    test('honors Retry-After HTTP-date on 429', () async {
      final cfg = AIServiceConfig.dev();
      final future = DateTime.now().toUtc().add(const Duration(seconds: 5));
      final header = future.toIso8601String();

      final fake = FakeClient(http.Response('', 429, headers: {'retry-after': header}));
      final client = VertexAIClient(config: cfg, httpClient: fake);

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, true);
      expect(res.errorOrNull, isA<AIServiceUnavailableError>());
      final err = res.errorOrNull as AIServiceUnavailableError;
      // retryAfter should be roughly 5 seconds (allow small leeway)
      expect(err.retryAfter, isNotNull);
      expect(err.retryAfter!.inSeconds, greaterThanOrEqualTo(3));
      expect(err.retryAfter!.inSeconds, lessThanOrEqualTo(7));
    });

    test('interprets past Retry-After HTTP-date as zero on 500', () async {
      final cfg = AIServiceConfig.dev();
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final header = past.toIso8601String();

      final fake = FakeClient(http.Response('', 500, headers: {'retry-after': header}));
      final client = VertexAIClient(config: cfg, httpClient: fake);

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, true);
      expect(res.errorOrNull, isA<AIServiceUnavailableError>());
      final err = res.errorOrNull as AIServiceUnavailableError;
      expect(err.retryAfter, isNotNull);
      expect(err.retryAfter, Duration.zero);
    });
  });
}
