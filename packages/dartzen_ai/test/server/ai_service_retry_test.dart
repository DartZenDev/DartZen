import 'dart:async';
import 'dart:convert';

import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class SeqHttpClient extends http.BaseClient {
  int _calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _calls += 1;
    if (_calls == 1) {
      // Simulate 503 with Retry-After header
      const body = 'server error';
      final headers = {'retry-after': '1'};
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        503,
        headers: headers,
      );
    }

    // Success response with usage
    final success = jsonEncode({
      'text': 'ok',
      'requestId': 'req-1',
      'usage': {'inputTokens': 10, 'outputTokens': 5},
    });
    return http.StreamedResponse(Stream.value(utf8.encode(success)), 200);
  }

  @override
  void close() {}
}

/// A fake HTTP client that returns a 500 (with Retry-After) on the first
/// request and a 200 response on the second.
class FlakyHttpClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls += 1;
    if (calls == 1) {
      final body = jsonEncode({'error': 'temporary'});
      final headers = {'retry-after': '0'}; // immediate retry
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        503,
        headers: headers,
      );
    }

    final body = jsonEncode({'text': 'ok', 'requestId': 'rid'});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  void close() {}
}

void main() {
  group('AIService retry/backoff', () {
    test(
      'retries on service unavailable and records usage on success',
      () async {
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: SeqHttpClient(),
        );

        final tracker = AIUsageTracker();
        final enforcer = AIBudgetEnforcer(
          config: const AIBudgetConfig.unlimited(),
          usageTracker: tracker,
        );

        final svc = AIService(
          client: client,
          budgetEnforcer: enforcer,
          retryPolicy: const RetryPolicy(
            baseDelayMs: 1,
            maxDelayMs: 1,
            jitterFactor: 0.0,
          ),
        );

        final res = await svc.textGeneration(
          const TextGenerationRequest(prompt: 'hi', model: 'm'),
        );

        expect(res.isSuccess, isTrue);
        // Usage should have been recorded (cost > 0)
        expect(tracker.getGlobalUsage(), greaterThan(0.0));
      },
    );

    test('honors explicit retryAfter and retries operation', () async {
      final fakeHttp = FlakyHttpClient();
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: fakeHttp,
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(),
        usageTracker: tracker,
      );

      // Deterministic retry policy (no jitter).
      final svc = AIService(
        client: client,
        budgetEnforcer: enforcer,
        retryPolicy: const RetryPolicy(
          baseDelayMs: 1,
          maxDelayMs: 50,
          jitterFactor: 0.0,
        ),
      );

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );

      expect(res.isSuccess, isTrue);
      expect(
        fakeHttp.calls,
        equals(2),
        reason: 'HTTP client should have been invoked twice',
      );
    });
  });
}
