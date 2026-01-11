import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('TextGenerationResponse', () {
    test('creates response', () {
      const response = TextGenerationResponse(
        text: 'Generated text',
        requestId: 'req-123',
        usage: AIUsage(inputTokens: 10, outputTokens: 20),
      );

      expect(response.text, 'Generated text');
      expect(response.requestId, 'req-123');
      expect(response.usage?.totalTokens, 30);
      expect(response.usage?.totalTokens, 30);
    });

    test('serializes to and from JSON', () {
      const original = TextGenerationResponse(
        text: 'Test',
        requestId: 'req-1',
        usage: AIUsage(inputTokens: 5, outputTokens: 10),
        metadata: {'key': 'value'},
      );

      final json = original.toJson();
      final deserialized = TextGenerationResponse.fromJson(json);

      expect(deserialized.text, original.text);
      expect(deserialized.requestId, original.requestId);
      expect(deserialized.usage?.inputTokens, original.usage?.inputTokens);
      expect(deserialized.metadata, original.metadata);
    });
  });

  group('EmbeddingsResponse', () {
    test('creates response', () {
      const response = EmbeddingsResponse(
        embeddings: [
          [1.0, 2.0, 3.0],
          [4.0, 5.0, 6.0],
        ],
        requestId: 'req-123',
      );

      expect(response.embeddings.length, 2);
      expect(response.embeddings[0], [1.0, 2.0, 3.0]);
      expect(response.requestId, 'req-123');
    });

    test('serializes to and from JSON', () {
      const original = EmbeddingsResponse(
        embeddings: [
          [1.0, 2.0],
        ],
        requestId: 'req-1',
        usage: AIUsage(inputTokens: 5, outputTokens: 0),
      );

      final json = original.toJson();
      final deserialized = EmbeddingsResponse.fromJson(json);

      expect(deserialized.embeddings, original.embeddings);
      expect(deserialized.requestId, original.requestId);
      expect(deserialized.usage?.inputTokens, original.usage?.inputTokens);
    });
  });

  group('ClassificationResponse', () {
    test('creates response', () {
      const response = ClassificationResponse(
        label: 'positive',
        confidence: 0.95,
        requestId: 'req-123',
        allScores: {'positive': 0.95, 'negative': 0.05},
      );

      expect(response.label, 'positive');
      expect(response.confidence, 0.95);
      expect(response.allScores?['positive'], 0.95);
    });

    test('serializes to and from JSON', () {
      const original = ClassificationResponse(
        label: 'test',
        confidence: 0.8,
        requestId: 'req-1',
        allScores: {'test': 0.8, 'other': 0.2},
        usage: AIUsage(inputTokens: 10, outputTokens: 5),
      );

      final json = original.toJson();
      final deserialized = ClassificationResponse.fromJson(json);

      expect(deserialized.label, original.label);
      expect(deserialized.confidence, original.confidence);
      expect(deserialized.allScores, original.allScores);
      expect(deserialized.usage?.inputTokens, original.usage?.inputTokens);
    });
  });

  group('AIUsage', () {
    test('calculates total tokens', () {
      const usage = AIUsage(inputTokens: 10, outputTokens: 20);
      expect(usage.totalTokens, 30);
    });

    test('serializes to and from JSON', () {
      const original = AIUsage(inputTokens: 15, outputTokens: 25);

      final json = original.toJson();
      final deserialized = AIUsage.fromJson(json);

      expect(deserialized.inputTokens, original.inputTokens);
      expect(deserialized.outputTokens, original.outputTokens);
      expect(deserialized.totalTokens, original.totalTokens);
    });
  });
}
