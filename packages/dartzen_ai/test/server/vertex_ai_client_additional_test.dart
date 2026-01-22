import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class SimpleFakeClient extends http.BaseClient {
  SimpleFakeClient(this._status, this._body, [this._headers = const {}]);

  final int _status;
  final String _body;
  final Map<String, String> _headers;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(const Utf8Encoder().convert(_body)),
        _status,
        headers: _headers,
      );

  @override
  void close() {}
}

void main() {
  group('VertexAIClient additional', () {
    test(
      'maps 429 with numeric Retry-After to AIServiceUnavailableError',
      () async {
        final fake = SimpleFakeClient(429, '', {'retry-after': '120'});
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: fake,
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );
        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter?.inSeconds, equals(120));
      },
    );

    test('maps 429 without Retry-After to AIQuotaExceededError', () async {
      final fake = SimpleFakeClient(429, '');
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

    test(
      'maps 503 with HTTP-date Retry-After to AIServiceUnavailableError',
      () async {
        final when = DateTime.now().toUtc().add(const Duration(seconds: 30));
        final hdr = when.toIso8601String();
        final fake = SimpleFakeClient(503, '', {'retry-after': hdr});
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: fake,
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );
        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, isNotNull);
        expect(err.retryAfter!.inSeconds, greaterThanOrEqualTo(28));
      },
    );

    test(
      'maps 500 without Retry-After to AIServiceUnavailableError with default',
      () async {
        final fake = SimpleFakeClient(500, '');
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: fake,
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );
        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, equals(const Duration(seconds: 2)));
      },
    );

    test('maps 401 to AIAuthenticationError', () async {
      final fake = SimpleFakeClient(401, '');
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: fake,
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIAuthenticationError>());
    });
  });
}
