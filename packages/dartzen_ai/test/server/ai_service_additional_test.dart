import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class CountingFakeClient extends http.BaseClient {
  final http.Response response;
  int sendCount = 0;

  CountingFakeClient(this.response);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sendCount++;
    return http.StreamedResponse(
      Stream.value(const Utf8Encoder().convert(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close() {}
}

class CloseThrowClient extends http.BaseClient {
  final http.Response response;
  CloseThrowClient(this.response);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(const Utf8Encoder().convert(response.body)),
        response.statusCode,
        headers: response.headers,
      );

  @override
  void close() {
    throw StateError('close-failed');
  }
}

void main() {
  group('AIService additional', () {
    test('does not retry on authentication error', () async {
      // 401 from Vertex -> AIAuthenticationError and should not retry
      final resp = http.Response('', 401);
      final counting = CountingFakeClient(resp);
      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: counting,
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(),
        usageTracker: tracker,
      );

      final svc = AIService(client: vertex, budgetEnforcer: enforcer);

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'x', model: 'm'),
      );
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIAuthenticationError>());

      // should have been called exactly once
      expect(counting.sendCount, equals(1));
    });

    test('close swallows client.close exceptions', () async {
      final resp = http.Response(jsonEncode({'text': 'ok'}), 200);
      final bad = CloseThrowClient(resp);

      final vertex = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: bad,
      );

      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: AIBudgetConfig(),
        usageTracker: tracker,
      );

      final svc = AIService(client: vertex, budgetEnforcer: enforcer);

      // close should not throw despite underlying client.close throwing
      await svc.close();
    });
  });
}
