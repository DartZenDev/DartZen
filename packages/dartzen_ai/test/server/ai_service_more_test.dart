import 'dart:async';
import 'dart:convert';

import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

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
  }) async => List<TelemetryEvent>.from(events);
}

class BadRequestClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls += 1;
    const body = 'bad request';
    return http.StreamedResponse(Stream.value(utf8.encode(body)), 400);
  }

  @override
  void close() {}
}

class SuccessClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls += 1;
    final success = jsonEncode({
      'text': 'ok',
      'requestId': 'req-xyz',
      'usage': {'inputTokens': 2, 'outputTokens': 3},
    });
    return http.StreamedResponse(
      Stream.value(utf8.encode(success)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  void close() {}
}

void main() {
  group('AIService telemetry', () {
    test('emits budget exceeded telemetry for textGeneration', () async {
      final tracker = AIUsageTracker();
      // Make global usage exceed the monthly limit
      tracker.recordUsage('someMethod', 100.0);

      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(monthlyLimit: 1.0),
        usageTracker: tracker,
      );

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient:
            SuccessClient(), // won't be invoked due to budget short-circuit
      );

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
        const TextGenerationRequest(prompt: 'hi', model: 'm1'),
      );

      expect(res.isFailure, isTrue);

      final events = await store.queryEvents();
      expect(
        events.any((e) => e.name == 'ai.textgeneration.budget.exceeded'),
        isTrue,
      );
    });

    test(
      'does not retry on invalid request and emits failure telemetry',
      () async {
        final badHttp = BadRequestClient();
        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: badHttp,
        );

        final tracker = AIUsageTracker();
        final enforcer = AIBudgetEnforcer(
          config: const AIBudgetConfig.unlimited(),
          usageTracker: tracker,
        );

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
          const TextGenerationRequest(prompt: 'x', model: 'm2'),
        );

        expect(res.isFailure, isTrue);
        expect(
          badHttp.calls,
          equals(1),
          reason: 'Should not retry invalid requests',
        );

        final events = await store.queryEvents();
        expect(
          events.any((e) => e.name == 'ai.textgeneration.failure'),
          isTrue,
        );
      },
    );

    test('emits success telemetry on successful generation', () async {
      final successHttp = SuccessClient();
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: successHttp,
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: tracker,
      );

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
        const TextGenerationRequest(prompt: 'ok', model: 'm3'),
      );

      expect(res.isSuccess, isTrue);

      final events = await store.queryEvents();
      expect(events.any((e) => e.name == 'ai.textgeneration.success'), isTrue);
    });
  });
}
