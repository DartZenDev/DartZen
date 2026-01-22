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

class _SeqResponseClient extends http.BaseClient {
  _SeqResponseClient(this._responseBody, this._status);

  final String _responseBody;
  final int _status;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(_responseBody);
    return http.StreamedResponse(Stream.value(bytes), _status, headers: {'content-type': 'application/json'});
  }

  @override
  void close() {}
}

class InMemoryTelemetryStore implements TelemetryStore {
  final List<TelemetryEvent> events = [];

  @override
  Future<void> addEvent(TelemetryEvent event) async => events.add(event);

  @override
  Future<List<TelemetryEvent>> queryEvents({String? userId, String? sessionId, String? correlationId, String? scope, DateTime? from, DateTime? to, int? limit}) async => List<TelemetryEvent>.from(events);
}

void main() {
  group('AIService additional branches', () {
    test('embeddings success records usage and emits telemetry', () async {
      final resp = jsonEncode({
        'embeddings': [ [0.1, 0.2], [0.3, 0.4] ],
        'requestId': 'r-emb',
        'usage': {'inputTokens': 5, 'outputTokens': 0}
      });

      final client = VertexAIClient(config: AIServiceConfig.dev(), httpClient: _SeqResponseClient(resp, 200));
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(config: const AIBudgetConfig.unlimited(), usageTracker: tracker);

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final svc = AIService(client: client, budgetEnforcer: enforcer, telemetryClient: telemetry, retryPolicy: const RetryPolicy(baseDelayMs: 1, maxDelayMs: 1, jitterFactor: 0.0));

      final res = await svc.embeddings(const EmbeddingsRequest(texts: ['a', 'b'], model: 'm-emb'));

      expect(res.isSuccess, isTrue);

      // usage recorded via budget enforcer
      expect(tracker.getGlobalUsage(), greaterThan(0.0));

      final events = await store.queryEvents();
      expect(events.any((e) => e.name == 'ai.embeddings.success'), isTrue);
    });

    test('classification success records usage and emits telemetry', () async {
      final resp = jsonEncode({
        'label': 'positive',
        'confidence': 0.92,
        'requestId': 'r-cls',
        'usage': {'inputTokens': 2, 'outputTokens': 0}
      });

      final client = VertexAIClient(config: AIServiceConfig.dev(), httpClient: _SeqResponseClient(resp, 200));
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(config: const AIBudgetConfig.unlimited(), usageTracker: tracker);

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final svc = AIService(client: client, budgetEnforcer: enforcer, telemetryClient: telemetry, retryPolicy: const RetryPolicy(baseDelayMs: 1, maxDelayMs: 1, jitterFactor: 0.0));

      final res = await svc.classification(const ClassificationRequest(text: 'hello', model: 'm-cls'));

      expect(res.isSuccess, isTrue);

      expect(tracker.getGlobalUsage(), greaterThan(0.0));

      final events = await store.queryEvents();
      expect(events.any((e) => e.name == 'ai.classification.success'), isTrue);
    });

    test('classification failure emits failure telemetry and returns error', () async {
      // return 400 to simulate invalid request
      final client = VertexAIClient(config: AIServiceConfig.dev(), httpClient: _SeqResponseClient(jsonEncode({'message': 'bad'}), 400));
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(config: const AIBudgetConfig.unlimited(), usageTracker: tracker);

      final store = InMemoryTelemetryStore();
      final telemetry = TelemetryClient(store);

      final svc = AIService(client: client, budgetEnforcer: enforcer, telemetryClient: telemetry, retryPolicy: const RetryPolicy(baseDelayMs: 1, maxDelayMs: 1, jitterFactor: 0.0));

      final res = await svc.classification(const ClassificationRequest(text: 'bad', model: 'm-cls'));

      expect(res.isFailure, isTrue);

      final events = await store.queryEvents();
      expect(events.any((e) => e.name == 'ai.classification.failure'), isTrue);
    });
  });
}
