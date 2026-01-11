import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('TextGenerationRequest', () {
    test('creates request', () {
      const request = TextGenerationRequest(
        prompt: 'Test prompt',
        model: 'gemini-pro',
      );

      expect(request.prompt, 'Test prompt');
      expect(request.model, 'gemini-pro');
      expect(request.config.temperature, 0.7);
      expect(request.metadata, null);
    });

    test('converts to JSON', () {
      const request = TextGenerationRequest(
        prompt: 'Test',
        model: 'gemini-pro',
        metadata: {'key': 'value'},
      );

      final json = request.toJson();
      expect(json['prompt'], 'Test');
      expect(json['model'], 'gemini-pro');
      expect(json['metadata'], {'key': 'value'});
      expect(json['config'], isA<Map<String, dynamic>>());
    });
  });

  group('EmbeddingsRequest', () {
    test('creates request', () {
      const request = EmbeddingsRequest(
        texts: ['text1', 'text2'],
        model: 'textembedding-gecko',
      );

      expect(request.texts, ['text1', 'text2']);
      expect(request.model, 'textembedding-gecko');
      expect(request.metadata, null);
    });

    test('converts to JSON', () {
      const request = EmbeddingsRequest(
        texts: ['test'],
        model: 'model',
        metadata: {'key': 'value'},
      );

      final json = request.toJson();
      expect(json['texts'], ['test']);
      expect(json['model'], 'model');
      expect(json['metadata'], {'key': 'value'});
    });
  });

  group('ClassificationRequest', () {
    test('creates request', () {
      const request = ClassificationRequest(
        text: 'Test text',
        model: 'gemini-pro',
        labels: ['positive', 'negative'],
      );

      expect(request.text, 'Test text');
      expect(request.model, 'gemini-pro');
      expect(request.labels, ['positive', 'negative']);
      expect(request.config.temperature, 0.7);
    });

    test('converts to JSON', () {
      const request = ClassificationRequest(
        text: 'Test',
        model: 'model',
        labels: ['a', 'b'],
        metadata: {'key': 'value'},
      );

      final json = request.toJson();
      expect(json['text'], 'Test');
      expect(json['model'], 'model');
      expect(json['labels'], ['a', 'b']);
      expect(json['metadata'], {'key': 'value'});
      expect(json['config'], isA<Map<String, dynamic>>());
    });
  });
}
