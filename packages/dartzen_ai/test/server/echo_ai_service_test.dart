import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('EchoAIService', () {
    late EchoAIService service;

    setUp(() {
      service = const EchoAIService();
    });

    test('generates text with echo prefix', () async {
      const request = TextGenerationRequest(
        prompt: 'Hello world',
        model: 'gemini-pro',
      );

      final result = await service.textGeneration(request);

      expect(result.isSuccess, true);
      final response = result.dataOrNull!;
      expect(response.text, 'Echo: Hello world');
      expect(response.requestId, startsWith('echo_'));
      expect(response.usage?.inputTokens, 10);
      expect(response.usage?.outputTokens, 20);
      expect(response.metadata?['mode'], 'echo');
      expect(response.metadata?['model'], 'gemini-pro');
    });

    test('generates embeddings with mock vectors', () async {
      const request = EmbeddingsRequest(
        texts: ['text1', 'text2'],
        model: 'textembedding-gecko',
      );

      final result = await service.embeddings(request);

      expect(result.isSuccess, true);
      final response = result.dataOrNull!;
      expect(response.embeddings.length, 2);
      expect(response.embeddings[0].length, 768);
      expect(response.embeddings[1].length, 768);
      expect(response.requestId, startsWith('echo_'));
      expect(response.usage?.inputTokens, 10);
      expect(response.metadata?['mode'], 'echo');
    });

    test('classifies text based on length', () async {
      const shortRequest = ClassificationRequest(
        text: 'Short',
        model: 'gemini-pro',
      );

      final shortResult = await service.classification(shortRequest);
      expect(shortResult.isSuccess, true);
      expect(shortResult.dataOrNull!.label, 'short');
      expect(shortResult.dataOrNull!.confidence, 0.85);

      const longRequest = ClassificationRequest(
        text:
            'This is a much longer text that exceeds fifty characters in total length',
        model: 'gemini-pro',
      );

      final longResult = await service.classification(longRequest);
      expect(longResult.isSuccess, true);
      expect(longResult.dataOrNull!.label, 'long');
      expect(longResult.dataOrNull!.confidence, 0.85);
    });

    test('includes all scores in classification', () async {
      const request = ClassificationRequest(text: 'Test', model: 'gemini-pro');

      final result = await service.classification(request);

      expect(result.isSuccess, true);
      final response = result.dataOrNull!;
      expect(response.allScores, isNotNull);
      expect(response.allScores!.containsKey('long'), true);
      expect(response.allScores!.containsKey('short'), true);
      expect(
        response.allScores!['short']! + response.allScores!['long']!,
        closeTo(1.0, 0.01),
      );
    });

    test('simulates network delay', () async {
      const request = TextGenerationRequest(
        prompt: 'Test',
        model: 'gemini-pro',
      );

      final stopwatch = Stopwatch()..start();
      await service.textGeneration(request);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
    });
  });
}
