import 'dart:async';
import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/models/ai_response.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _CountingHttpClient extends http.BaseClient {
  _CountingHttpClient(this._status, this._body, [this._headers = const {}]);

  final int _status;
  final String _body;
  final Map<String, String> _headers;

  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls += 1;
    return http.StreamedResponse(Stream.value(utf8.encode(_body)), _status, headers: _headers);
  }

  @override
  void close() {}
}

class InMemoryTelemetryStore implements TelemetryStore {
  final List<TelemetryEvent> events = [];

  @override
  Future<void> addEvent(TelemetryEvent event) async {
    events.add(event);
  }

  @override
  Future<List<TelemetryEvent>> queryEvents({
    String? userId,
    String? sessionId,
    String? correlationId,
    String? scope,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async => events.where((e) => scope == null || e.scope == scope).toList();
}

void main() {
  group('AIService focused behavior', () {
    test(
      'textGeneration short-circuits when monthly budget exceeded',
      () async {
        final tracker = AIUsageTracker();
        // Record a large usage so monthlyLimit is exceeded
        tracker.recordUsage('textGeneration', 100.0);

        final enforcer = AIBudgetEnforcer(
          config: AIBudgetConfig(monthlyLimit: 1.0),
          usageTracker: tracker,
        );

        // HTTP client that would be used by VertexAIClient if invoked
        final counting = _CountingHttpClient(
          200,
          jsonEncode({'text': 'never', 'requestId': 'r'}),
        );
        final client = VertexAIClient(config: AIServiceConfig.dev(), httpClient: counting);

        final svc = AIService(client: client, budgetEnforcer: enforcer);

        final res = await svc.textGeneration(
          const TextGenerationRequest(prompt: 'x', model: 'm'),
        );

        expect(res.isFailure, isTrue);
        final err = res.errorOrNull;
        expect(err, isA<AIBudgetExceededError>());
        final be = err as AIBudgetExceededError;
        expect(be.limit, equals(1.0));
        expect(be.current, greaterThanOrEqualTo(100.0));
        // HTTP client should not have been invoked due to short-circuit
        expect(counting.calls, equals(0));
      },
    );

    test('textGeneration does not retry on invalid request error', () async {
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: tracker,
      );

      final counting = _CountingHttpClient(400, 'bad');
      final client = VertexAIClient(config: AIServiceConfig.dev(), httpClient: counting);

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
        const TextGenerationRequest(prompt: 'q', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIInvalidRequestError>());
      // Underlying HTTP client should have been invoked once and not retried
      expect(counting.calls, equals(1));
    });

    test(
      'textGeneration emits telemetry on success and records usage',
      () async {
        final tracker = AIUsageTracker();
        final enforcer = AIBudgetEnforcer(
          config: const AIBudgetConfig.unlimited(),
          usageTracker: tracker,
        );

        const usage = AIUsage(inputTokens: 10, outputTokens: 5);
        final body = jsonEncode({
          'text': 'ok',
          'requestId': 'r1',
          'usage': {'inputTokens': usage.inputTokens, 'outputTokens': usage.outputTokens},
        });
        final counting = _CountingHttpClient(200, body, {'content-type': 'application/json'});
        final client = VertexAIClient(config: AIServiceConfig.dev(), httpClient: counting);

        final store = InMemoryTelemetryStore();
        final telemetry = TelemetryClient(store);

        final svc = AIService(
          client: client,
          budgetEnforcer: enforcer,
          telemetryClient: telemetry,
          retryPolicy: const RetryPolicy(
            baseDelayMs: 1,
            maxDelayMs: 1,
            jitterFactor: 0.0,
          ),
        );

        final res = await svc.textGeneration(
          const TextGenerationRequest(prompt: 'hello', model: 'm'),
        );

        expect(res.isSuccess, isTrue);
        // Usage should have been recorded
        expect(tracker.getGlobalUsage(), greaterThan(0.0));
        // Telemetry event should include success entry
        final events = await store.queryEvents(scope: 'ai');
        expect(
          events.any((e) => e.name == 'ai.textgeneration.success'),
          isTrue,
        );
      },
    );
  });
}
