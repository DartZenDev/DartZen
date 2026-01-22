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

class RepeatingServerErrorClient extends http.BaseClient {
  RepeatingServerErrorClient({this.retryAfterHeader = '0'});

  final String retryAfterHeader;
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls += 1;
    final body = jsonEncode({'error': 'server error'});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      500,
      headers: {
        'retry-after': retryAfterHeader,
        'content-type': 'application/json',
      },
    );
  }

  @override
  void close() {}
}

void main() {
  group('AIService retry exhaustion', () {
    test('retries up to max attempts and returns last error', () async {
      final clientHttp = RepeatingServerErrorClient();
      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: clientHttp,
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: tracker,
      );

      // Use small retryPolicy but note AIService honors retry-after header when present
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

      expect(res.isFailure, isTrue);
      // Vertex client will have been called multiple times (maxAttempts in AIService is 3)
      expect(clientHttp.calls, greaterThanOrEqualTo(3));
      // Error should be AIServiceUnavailableError
      expect(res.errorOrNull, isA<AIServiceUnavailableError>());
    });
  });
}
