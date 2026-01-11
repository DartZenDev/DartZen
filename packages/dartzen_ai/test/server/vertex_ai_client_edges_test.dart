import 'dart:convert';

import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_request.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('VertexAIClient network resilience', () {
    test('HTTP exception returns AIServiceUnavailableError', () async {
      final throwingClient = MockClient((request) async {
        throw Exception('network down');
      });

      final client = VertexAIClient(
        config: const AIServiceConfig.dev(),
        httpClient: throwingClient,
      );

      final res = await client.generateText(
        const TextGenerationRequest(prompt: 'test', model: 'm'),
      );

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<AIServiceUnavailableError>());
    });

    test('classification with allScores parses correctly', () async {
      final body = jsonEncode({
        'label': 'spam',
        'confidence': 0.42,
        'requestId': 'r-1',
        'allScores': {'spam': 0.42, 'ham': 0.58},
        'usage': {'inputTokens': 2, 'outputTokens': 0, 'totalCost': 0.01},
      });

      final okClient = MockClient(
        (request) async => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final client = VertexAIClient(
        config: const AIServiceConfig.dev(),
        httpClient: okClient,
      );

      final res = await client.classify(
        const ClassificationRequest(text: 'test', model: 'm'),
      );

      expect(res.isSuccess, isTrue);
      final data = res.dataOrNull!;
      expect(data.label, equals('spam'));
      expect(data.confidence, closeTo(0.42, 1e-9));
      expect(data.allScores, isNotNull);
      expect(data.allScores!['ham'], closeTo(0.58, 1e-9));
    });
  });
}
