import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class SeqResponseClient extends http.BaseClient {
  SeqResponseClient(this._responses);
  final List<http.Response> _responses;
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = _responses[_index.clamp(0, _responses.length - 1)];
    _index++;
    return http.StreamedResponse(
      Stream.value(const Utf8Encoder().convert(resp.body)),
      resp.statusCode,
      headers: resp.headers,
    );
  }

  @override
  void close() {}
}

void main() {
  group('VertexAIClient parseRetryAfter edge cases', () {
    test(
      '429 with past HTTP-date -> AIServiceUnavailableError with zero retryAfter',
      () async {
        final past = DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 1))
            .toIso8601String();
        final fake = SeqResponseClient([
          http.Response('', 429, headers: {'retry-after': past}),
        ]);
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: fake,
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );
        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, equals(Duration.zero));
      },
    );

    test('429 with invalid Retry-After -> AIQuotaExceededError', () async {
      final fake = SeqResponseClient([
        http.Response('', 429, headers: {'retry-after': 'not-a-date'}),
      ]);
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: fake,
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIQuotaExceededError>());
    });
  });
}
