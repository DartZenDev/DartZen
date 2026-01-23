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

class SimpleSuccessClient extends http.BaseClient {
  final Map<String, dynamic> body;
  SimpleSuccessClient(this.body);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final jsonBody = jsonEncode(body);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonBody)),
      200,
      headers: {'content-type': 'application/json'},
    );
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
  }) async => List<TelemetryEvent>.from(events);
}

void main() {
  group('AIService remaining branches', () {
    test(
      'classification short-circuits when budget exceeded and emits telemetry',
      () async {
        final tracker = AIUsageTracker();
        // push usage over classification limit
        tracker.recordUsage('classification', 1000.0);

        final enforcer = AIBudgetEnforcer(
          config: AIBudgetConfig(classificationLimit: 1.0),
          usageTracker: tracker,
        );

        final store = InMemoryTelemetryStore();
        final telemetry = TelemetryClient(store);

        final client = VertexAIClient(
          config: AIServiceConfig.dev(),
          httpClient: SimpleSuccessClient({
            'label': 'ok',
            'requestId': 'r',
          }), // should not be invoked due to budget short-circuit
        );

        final svc = AIService(
          client: client,
          budgetEnforcer: enforcer,
          telemetryClient: telemetry,
        );

        final res = await svc.classification(
          const ClassificationRequest(text: 'x', model: 'm'),
        );

        expect(res.isFailure, isTrue);
        final events = await store.queryEvents();
        expect(
          events.any((e) => e.name == 'ai.classification.budget.exceeded'),
          isTrue,
        );
      },
    );

    test('telemetry is optional and does not throw when absent', () async {
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: SimpleSuccessClient({
          'label': 'ok',
          'requestId': 'r',
          'usage': {'inputTokens': 1, 'outputTokens': 1},
        }),
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: tracker,
      );

      // Do not provide telemetryClient (null)
      final svc = AIService(client: client, budgetEnforcer: enforcer);

      final res = await svc.classification(
        const ClassificationRequest(text: 'x', model: 'm'),
      );

      expect(res.isSuccess, isTrue);
    });
  });
}
