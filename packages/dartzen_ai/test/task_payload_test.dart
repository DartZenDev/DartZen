import 'dart:convert';

import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('AI task payload serialization', () {
    test('TextGenerationAiTask payload roundtrip', () {
      final task = TextGenerationAiTask(
        prompt: 'Write a haiku about code',
        model: 'gemini-pro',
        config: const AIModelConfig(temperature: 0.2, maxTokens: 50),
      );

      final payload = task.toPayload();
      final encoded = jsonEncode(payload);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = TextGenerationAiTask.fromPayload(decoded);

      expect(restored.prompt, equals(task.prompt));
      expect(restored.model, equals(task.model));
      expect(restored.config.maxTokens, equals(task.config.maxTokens));
      expect(restored.config.temperature, equals(task.config.temperature));
    });

    test('EmbeddingsAiTask payload roundtrip', () {
      final task = EmbeddingsAiTask(
        texts: const ['Hello world', 'Dart'],
        model: 'textembedding-gecko',
      );

      final payload = task.toPayload();
      final encoded = jsonEncode(payload);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = EmbeddingsAiTask.fromPayload(decoded);

      expect(restored.texts, equals(task.texts));
      expect(restored.model, equals(task.model));
    });

    test('ClassificationAiTask payload roundtrip', () {
      final task = ClassificationAiTask(
        text: 'I love this product',
        model: 'gemini-classifier',
        labels: const ['positive', 'negative'],
        config: const AIModelConfig(temperature: 0.0, maxTokens: 10),
      );

      final payload = task.toPayload();
      final encoded = jsonEncode(payload);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = ClassificationAiTask.fromPayload(decoded);

      expect(restored.text, equals(task.text));
      expect(restored.model, equals(task.model));
      expect(restored.labels, equals(task.labels));
      expect(restored.config.maxTokens, equals(task.config.maxTokens));
    });
  });
}
