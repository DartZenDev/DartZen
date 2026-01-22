import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _SeqHttpClient extends http.BaseClient {
  _SeqHttpClient(this._responses);
  final List<http.Response> _responses;
  var _i = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp =
        _responses[_i < _responses.length ? _i++ : _responses.length - 1];
    final bytes = utf8.encode(resp.body);
    final stream = Stream.value(Uint8List.fromList(bytes));
    return http.StreamedResponse(
      stream,
      resp.statusCode,
      headers: resp.headers,
      request: request,
    );
  }

  @override
  void close() {}

  int get calls => _i;
}

void main() {
  group('VertexAIClient error mapping', () {
    test('401 -> AIAuthenticationError', () async {
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: _SeqHttpClient([http.Response('', 401)]),
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIAuthenticationError>());
    });

    test('403 -> AIAuthenticationError', () async {
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: _SeqHttpClient([http.Response('', 403)]),
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIAuthenticationError>());
    });

    test(
      '429 with numeric Retry-After -> AIServiceUnavailableError with retryAfter seconds',
      () async {
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: _SeqHttpClient([
            http.Response('', 429, headers: {'retry-after': '5'}),
          ]),
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );

        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, isNotNull);
        expect(err.retryAfter!.inSeconds, equals(5));
      },
    );

    test(
      '429 with HTTP-date -> AIServiceUnavailableError with parsed duration',
      () async {
        final future = DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 10))
            .toIso8601String();
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: _SeqHttpClient([
            http.Response('', 429, headers: {'retry-after': future}),
          ]),
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );

        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, isNotNull);
        expect(err.retryAfter!.inSeconds, greaterThanOrEqualTo(9));
      },
    );

    test('429 without Retry-After -> AIQuotaExceededError', () async {
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: _SeqHttpClient([http.Response('', 429)]),
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIQuotaExceededError>());
    });

    test(
      '500 with Retry-After -> AIServiceUnavailableError with parsed retryAfter',
      () async {
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: _SeqHttpClient([
            http.Response('', 500, headers: {'retry-after': '3'}),
          ]),
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );

        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, isNotNull);
        expect(err.retryAfter!.inSeconds, equals(3));
      },
    );

    test(
      '500 without Retry-After -> AIServiceUnavailableError with default',
      () async {
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: _SeqHttpClient([http.Response('', 500)]),
        );

        final res = await client.generateText(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );

        expect(res.isFailure, isTrue);
        final err = res.errorOrNull as AIServiceUnavailableError;
        expect(err.retryAfter, isNotNull);
        expect(err.retryAfter!.inSeconds, equals(2));
      },
    );

    test('400 returns AIInvalidRequestError with body included', () async {
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: _SeqHttpClient([http.Response('bad input', 400)]),
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIInvalidRequestError>());
      final err = res.errorOrNull as AIInvalidRequestError;
      expect(err.reason, contains('HTTP 400'));
    });
  });
}
