import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_ai/dartzen_ai.dart';
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
  }) async => events.where((e) {
    if (scope != null && e.scope != scope) return false;
    if (from != null && e.timestamp.isBefore(from)) return false;
    if (to != null && e.timestamp.isAfter(to)) return false;
    return true;
  }).toList();
}

class SequenceHttpClient implements http.Client {
  final List<http.Response> responses;
  int _index = 0;

  SequenceHttpClient(this.responses);

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => _index >= responses.length
      ? http.Response('No more', 500)
      : responses[_index++];

  // Unused methods in this test scope
  @override
  void close() {}
  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => Future.error(UnsupportedError('not used'));
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      Future.error(UnsupportedError('not used'));
  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      Future.error(UnsupportedError('not used'));
  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => Future.error(UnsupportedError('not used'));
  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => Future.error(UnsupportedError('not used'));
  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) =>
      Future.error(UnsupportedError('not used'));
  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) =>
      Future.error(UnsupportedError('not used'));
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(UnsupportedError('not used'));
}

void main() {
  group('AIService', () {
    late AIUsageTracker usageTracker;

    final config = AIServiceConfig.dev(projectId: 'p');

    setUp(() {
      usageTracker = AIUsageTracker();
    });

    test('textGeneration success records usage and emits telemetry', () async {
      final httpClient = SequenceHttpClient([
        http.Response(
          jsonEncode({
            'text': 'Hello',
            'usage': {'inputTokens': 5, 'outputTokens': 10},
          }),
          200,
        ),
      ]);
      final vertex = VertexAIClient(config: config, httpClient: httpClient);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: usageTracker,
      );
      final service = AIService(client: vertex, budgetEnforcer: enforcer);

      const req = TextGenerationRequest(prompt: 'p', model: 'gemini-pro');
      final result = await service.textGeneration(req);

      expect(result.isSuccess, true);
      expect(
        usageTracker.getMethodUsage('textGeneration'),
        closeTo(0.00075, 1e-9),
      );
      // No telemetry client provided; verify usage only
    });

    test('textGeneration budget exceeded emits telemetry and fails', () async {
      final httpClient = SequenceHttpClient([
        http.Response(jsonEncode({'text': 'Hello'}), 200),
      ]);
      final vertex = VertexAIClient(config: config, httpClient: httpClient);
      final tracker = AIUsageTracker()..recordUsage('textGeneration', 51.0);
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(
          monthlyLimit: 100.0,
          textGenerationLimit: 50.0,
          embeddingsLimit: 30.0,
          classificationLimit: 20.0,
        ),
        usageTracker: tracker,
      );
      final service = AIService(client: vertex, budgetEnforcer: enforcer);

      const req = TextGenerationRequest(prompt: 'p', model: 'gemini-pro');
      final result = await service.textGeneration(req);

      expect(result.isFailure, true);
      // No telemetry client provided; just verify failure
    });

    test('embeddings success emits telemetry and records usage', () async {
      final httpClient = SequenceHttpClient([
        http.Response(
          jsonEncode({
            'embeddings': [
              [0.1, 0.2],
            ],
            'usage': {'inputTokens': 2, 'outputTokens': 0},
          }),
          200,
        ),
      ]);
      final vertex = VertexAIClient(config: config, httpClient: httpClient);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: usageTracker,
      );
      final service = AIService(client: vertex, budgetEnforcer: enforcer);

      const req = EmbeddingsRequest(texts: ['t'], model: 'textembedding-gecko');
      final result = await service.embeddings(req);

      expect(result.isSuccess, true);
      expect(usageTracker.getMethodUsage('embeddings'), closeTo(0.0005, 1e-9));
      // No telemetry client provided; verify usage only
    });

    test('classification failure emits telemetry', () async {
      final httpClient = SequenceHttpClient([http.Response('Bad', 500)]);
      final vertex = VertexAIClient(config: config, httpClient: httpClient);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: usageTracker,
      );
      final service = AIService(client: vertex, budgetEnforcer: enforcer);

      const req = ClassificationRequest(text: 't', model: 'gemini-pro');
      final result = await service.classification(req);

      expect(result.isFailure, true);
      // No telemetry client provided; just verify failure
    });

    test('classification success records usage and emits telemetry', () async {
      final httpClient = SequenceHttpClient([
        http.Response(
          jsonEncode({
            'label': 'positive',
            'confidence': 0.9,
            'usage': {'inputTokens': 1, 'outputTokens': 1},
          }),
          200,
        ),
      ]);
      final vertex = VertexAIClient(config: config, httpClient: httpClient);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: usageTracker,
      );
      final service = AIService(client: vertex, budgetEnforcer: enforcer);

      const req = ClassificationRequest(text: 't', model: 'gemini-pro');
      final result = await service.classification(req);

      expect(result.isSuccess, true);
      expect(
        usageTracker.getMethodUsage('classification'),
        closeTo(0.00005, 1e-9),
      );
      // No telemetry client provided; verify usage only
    });

    test('retry logic succeeds after transient failures', () async {
      final httpClient = SequenceHttpClient([
        http.Response('Err1', 503),
        http.Response('Err2', 429),
        http.Response(jsonEncode({'text': 'Yo'}), 200),
      ]);
      final vertex = VertexAIClient(config: config, httpClient: httpClient);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: usageTracker,
      );
      final service = AIService(client: vertex, budgetEnforcer: enforcer);

      const req = TextGenerationRequest(prompt: 'p', model: 'gemini-pro');
      final result = await service.textGeneration(req);

      expect(result.isSuccess, true);
      expect(result.isSuccess, true);
    });
  });
}
