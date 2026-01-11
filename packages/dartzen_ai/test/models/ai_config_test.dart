import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('AIServiceConfig', () {
    test('creates production config', () {
      final config = AIServiceConfig(
        projectId: 'test-project',
        region: 'us-central1',
        credentialsJson: '{"key": "value"}',
        budgetConfig: AIBudgetConfig(monthlyLimit: 100.0),
      );

      expect(config.projectId, 'test-project');
      expect(config.region, 'us-central1');
      expect(config.credentialsJson, '{"key": "value"}');
      expect(config.isDev, false);
      expect(config.budgetConfig.monthlyLimit, 100.0);
    });

    test('creates dev config', () {
      final config = AIServiceConfig.dev();

      expect(config.projectId, 'dev-project');
      expect(config.region, 'us-central1');
      expect(config.credentialsJson, null);
      expect(config.isDev, true);
      expect(config.budgetConfig.hasLimits, false);
    });
  });

  group('AIBudgetConfig', () {
    test('creates config with limits', () {
      final config = AIBudgetConfig(
        monthlyLimit: 100.0,
        textGenerationLimit: 50.0,
        embeddingsLimit: 30.0,
        classificationLimit: 20.0,
      );

      expect(config.monthlyLimit, 100.0);
      expect(config.textGenerationLimit, 50.0);
      expect(config.embeddingsLimit, 30.0);
      expect(config.classificationLimit, 20.0);
      expect(config.hasLimits, true);
    });

    test('creates unlimited config', () {
      const config = AIBudgetConfig.unlimited();

      expect(config.monthlyLimit, null);
      expect(config.textGenerationLimit, null);
      expect(config.embeddingsLimit, null);
      expect(config.classificationLimit, null);
      expect(config.hasLimits, false);
    });
  });

  group('AIModelConfig', () {
    test('creates config with defaults', () {
      const config = AIModelConfig();

      expect(config.temperature, 0.7);
      expect(config.maxTokens, 1024);
      expect(config.topP, 0.95);
      expect(config.topK, 40);
    });

    test('creates config with custom values', () {
      const config = AIModelConfig(
        temperature: 0.5,
        maxTokens: 2048,
        topP: 0.9,
        topK: 50,
      );

      expect(config.temperature, 0.5);
      expect(config.maxTokens, 2048);
      expect(config.topP, 0.9);
      expect(config.topK, 50);
    });

    test('converts to JSON', () {
      const config = AIModelConfig(temperature: 0.8, maxTokens: 512);
      final json = config.toJson();

      expect(json['temperature'], 0.8);
      expect(json['maxTokens'], 512);
      expect(json['topP'], 0.95);
      expect(json['topK'], 40);
    });
  });
}
