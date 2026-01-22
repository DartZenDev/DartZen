import 'dart:async';
import 'dart:convert';

import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
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
    final stream = Stream.value(bytes);
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
  group('AIService targeted', () {
    test('non-retryable invalid request returns immediately', () async {
      final seq = _SeqHttpClient([http.Response('bad', 400)]);

      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: AIUsageTracker(),
      );
      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: seq,
      );
      final svc = AIService(client: vertex, budgetEnforcer: enforcer);

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIInvalidRequestError>());
      expect(
        seq.calls,
        equals(1),
        reason: 'Should not retry non-retryable errors',
      );
    });

    test('authentication error is non-retryable', () async {
      final seq = _SeqHttpClient([http.Response('', 401)]);

      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: AIUsageTracker(),
      );
      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: seq,
      );
      final svc = AIService(client: vertex, budgetEnforcer: enforcer);

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIAuthenticationError>());
      expect(seq.calls, equals(1));
    });

    test(
      'service unavailable with retryAfter allows retry and eventually succeeds',
      () async {
        final seq = _SeqHttpClient([
          http.Response('', 500, headers: {'retry-after': '1'}),
          http.Response(jsonEncode({'text': 'ok', 'requestId': 'r'}), 200),
        ]);

        final enforcer = AIBudgetEnforcer(
          config: const AIBudgetConfig.unlimited(),
          usageTracker: AIUsageTracker(),
        );
        final vertex = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: seq,
        );
        final svc = AIService(
          client: vertex,
          budgetEnforcer: enforcer,
          retryPolicy: const RetryPolicy(
            baseDelayMs: 1,
            maxDelayMs: 10,
            jitterFactor: 0.0,
          ),
        );

        final res = await svc.textGeneration(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );

        expect(res.isSuccess, isTrue);
        expect(seq.calls, greaterThanOrEqualTo(2));
      },
    );
  });
}
