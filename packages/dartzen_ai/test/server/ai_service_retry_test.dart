import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class CountingClient implements http.Client {
  final List<http.Response> responses;
  int calls = 0;

  CountingClient(this.responses);

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    calls++;
    if (calls - 1 >= responses.length) return http.Response('No more', 500);
    return responses[calls - 1];
  }

  @override
  void close() {}

  // Unused methods
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
  group('AIService retry policy', () {
    final config = AIServiceConfig.dev(projectId: 'p');

    test('does not retry on invalid request (400)', () async {
      final client = CountingClient([http.Response('Bad', 400)]);
      final vertex = VertexAIClient(config: config, httpClient: client);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: AIUsageTracker(),
      );
      final service = AIService(
        client: vertex,
        budgetEnforcer: enforcer,
        retryPolicy: const RetryPolicy(baseDelayMs: 1),
      );

      const req = TextGenerationRequest(prompt: 'p', model: 'm');
      final result = await service.textGeneration(req);

      expect(result.isFailure, true);
      expect(client.calls, 1);
    });

    test('honors Retry-After from service unavailable', () async {
      final headers = {'retry-after': '0'}; // zero seconds to avoid delay
      final client = CountingClient([
        http.Response('Err', 503, headers: headers),
        http.Response(jsonEncode({'text': 'ok'}), 200),
      ]);
      final vertex = VertexAIClient(config: config, httpClient: client);
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: AIUsageTracker(),
      );
      final service = AIService(
        client: vertex,
        budgetEnforcer: enforcer,
        retryPolicy: const RetryPolicy(baseDelayMs: 1),
      );

      const req = TextGenerationRequest(prompt: 'p', model: 'm');
      final result = await service.textGeneration(req);

      expect(result.isSuccess, true);
      expect(client.calls, 2);
    });
  });
}
