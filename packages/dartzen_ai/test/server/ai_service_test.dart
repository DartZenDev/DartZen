import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class FakeClient extends http.BaseClient {
  final http.Response response;
  final bool throwOnSend;

  FakeClient(this.response, {this.throwOnSend = false});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
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

class InMemoryTelemetryStore implements TelemetryStore {
  final List<TelemetryEvent> _events = [];

  @override
  Future<void> addEvent(TelemetryEvent event) async {
    _events.add(event);
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
  }) async => List<TelemetryEvent>.from(_events);

  List<TelemetryEvent> get events => List.unmodifiable(_events);
}

void main() {
  group('AIService', () {
    test('short-circuits when budget exceeded and emits telemetry', () async {
      final tracker = AIUsageTracker();
      tracker.recordUsage('textGeneration', 50.0);

      final config = AIBudgetConfig(monthlyLimit: 40.0);
      final enforcer = AIBudgetEnforcer(config: config, usageTracker: tracker);

      final fakeClient = FakeClient(http.Response('', 200), throwOnSend: true);
      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: fakeClient,
      );

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final svc = AIService(
        client: vertex,
        budgetEnforcer: enforcer,
        telemetryClient: telemetry,
      );

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );
      expect(res.isFailure, true);
      expect(res.errorOrNull, isA<AIBudgetExceededError>());

      final events = await store.queryEvents(scope: 'ai');
      expect(
        events.any((e) => e.name == 'ai.textgeneration.budget.exceeded'),
        true,
      );
    });

    test('records usage and emits success telemetry on success', () async {
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(),
        usageTracker: tracker,
      );

      final body = jsonEncode({
        'text': 'ok',
        'requestId': 'rid',
        'usage': {'inputTokens': 2, 'outputTokens': 3},
      });
      final fakeClient = FakeClient(http.Response(body, 200));
      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: fakeClient,
      );

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final svc = AIService(
        client: vertex,
        budgetEnforcer: enforcer,
        telemetryClient: telemetry,
      );

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );
      expect(res.isSuccess, true);

      // Cost should have been recorded
      expect(tracker.getGlobalUsage(), greaterThan(0.0));

      final events = await store.queryEvents(scope: 'ai');
      expect(events.any((e) => e.name == 'ai.textgeneration.success'), true);
    });
  });
}
