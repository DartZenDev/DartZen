import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const body = '{}';
    return http.StreamedResponse(Stream.value(body.codeUnits), 200);
  }

  @override
  void close() {}
}

void main() {
  group('AIService budget checks', () {
    test('textGeneration short-circuits when budget exceeded', () async {
      final tracker = AIUsageTracker();

      // Record usage to reach the method limit exactly (>= triggers error).
      tracker.recordUsage('textGeneration', 10.0);

      final config = AIBudgetConfig(textGenerationLimit: 10.0);
      final enforcer = AIBudgetEnforcer(config: config, usageTracker: tracker);

      final client = VertexAIClient(
        config: AIServiceConfig.dev(),
        httpClient: NoopHttpClient(),
      );

      final svc = AIService(client: client, budgetEnforcer: enforcer);

      final res = await svc.textGeneration(
        const TextGenerationRequest(prompt: 'hi', model: 'm'),
      );

      expect(res.isFailure, isTrue);
    });
  });
}
