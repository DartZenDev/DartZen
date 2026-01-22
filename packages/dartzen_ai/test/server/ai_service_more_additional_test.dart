import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
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
  group('AIService additional targeted', () {
    test(
      'embeddings short-circuits when budget exceeded and emits telemetry',
      () async {
        final tracker = AIUsageTracker();
        tracker.recordUsage('embeddings', 1000.0);

        final enforcer = AIBudgetEnforcer(
          config: AIBudgetConfig(monthlyLimit: 1.0),
          usageTracker: tracker,
        );

        final fakeClient = SeqResponseClient([http.Response('', 200)]);
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

        final res = await svc.embeddings(
          const EmbeddingsRequest(texts: ['a'], model: 'm'),
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull, isA<AIBudgetExceededError>());

        final events = await store.queryEvents(scope: 'ai');
        expect(
          events.any((e) => e.name == 'ai.embeddings.budget.exceeded'),
          isTrue,
        );
      },
    );

    test('withRetry honors explicit retryAfter then succeeds', () async {
      // First response: 503 with Retry-After header
      final fail = http.Response('', 503, headers: {'retry-after': '1'});
      final okBody = jsonEncode({'text': 'ok', 'requestId': 'r'});
      final ok = http.Response(
        okBody,
        200,
        headers: {'content-type': 'application/json'},
      );
      final seq = SeqResponseClient([fail, ok]);

      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: seq,
      );
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(),
        usageTracker: tracker,
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
    });

    test('classification failure emits telemetry event', () async {
      final bad = http.Response(
        jsonEncode({'message': 'bad'}),
        400,
        headers: {'content-type': 'application/json'},
      );
      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: SeqResponseClient([bad]),
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(),
        usageTracker: tracker,
      );

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final svc = AIService(
        client: client,
        budgetEnforcer: enforcer,
        telemetryClient: telemetry,
      );

      final res = await svc.classification(
        const ClassificationRequest(text: 'x', model: 'm'),
      );
      expect(res.isFailure, isTrue);

      final events = await store.queryEvents(scope: 'ai');
      expect(events.any((e) => e.name == 'ai.classification.failure'), isTrue);
    });
  });
}
