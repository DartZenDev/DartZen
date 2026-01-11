import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:test/test.dart';

void main() {
  group('AIBudgetEnforcer', () {
    late AIUsageTracker tracker;
    late AIBudgetEnforcer enforcer;

    setUp(() {
      tracker = AIUsageTracker();
      final config = AIBudgetConfig(
        monthlyLimit: 100.0,
        textGenerationLimit: 50.0,
        embeddingsLimit: 30.0,
        classificationLimit: 20.0,
      );
      enforcer = AIBudgetEnforcer(config: config, usageTracker: tracker);
    });

    test('allows request within budget', () {
      final result = enforcer.checkTextGenerationBudget();
      expect(result.isSuccess, true);
    });

    test('blocks request when method budget exceeded', () {
      tracker.recordUsage('textGeneration', 55.0);

      final result = enforcer.checkTextGenerationBudget();
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<AIBudgetExceededError>());

      final error = result.errorOrNull! as AIBudgetExceededError;
      expect(error.limit, 50.0);
      expect(error.current, 55.0);
    });

    test('blocks request when global budget exceeded', () {
      tracker.recordUsage('textGeneration', 40.0);
      tracker.recordUsage('embeddings', 25.0);
      tracker.recordUsage('classification', 40.0);

      final result = enforcer.checkTextGenerationBudget();
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<AIBudgetExceededError>());

      final error = result.errorOrNull! as AIBudgetExceededError;
      expect(error.limit, 100.0);
      expect(error.current, 105.0);
    });

    test('records usage correctly', () {
      enforcer.recordUsage(AIMethod.textGeneration, 10.0);
      enforcer.recordUsage(AIMethod.textGeneration, 5.0);

      expect(tracker.getMethodUsage('textGeneration'), 15.0);
      expect(tracker.getGlobalUsage(), 15.0);
    });

    test('allows unlimited budget', () {
      const unlimitedConfig = AIBudgetConfig.unlimited();
      final unlimitedEnforcer = AIBudgetEnforcer(
        config: unlimitedConfig,
        usageTracker: tracker,
      );

      tracker.recordUsage('textGeneration', 1000000.0);

      final result = unlimitedEnforcer.checkTextGenerationBudget();
      expect(result.isSuccess, true);
    });

    test('blocks embeddings when method budget exceeded', () {
      tracker.recordUsage('embeddings', 31.0);

      final result = enforcer.checkEmbeddingsBudget();
      expect(result.isFailure, true);
      final error = result.errorOrNull! as AIBudgetExceededError;
      expect(error.limit, 30.0);
      expect(error.current, 31.0);
    });

    test('blocks classification when method budget exceeded', () {
      tracker.recordUsage('classification', 25.0);

      final result = enforcer.checkClassificationBudget();
      expect(result.isFailure, true);
      final error = result.errorOrNull! as AIBudgetExceededError;
      expect(error.limit, 20.0);
      expect(error.current, 25.0);
    });
  });

  group('AIUsageTracker', () {
    late AIUsageTracker tracker;

    setUp(() {
      tracker = AIUsageTracker();
    });

    test('starts with zero usage', () {
      expect(tracker.getGlobalUsage(), 0.0);
      expect(tracker.getMethodUsage('textGeneration'), 0.0);
    });

    test('records and retrieves usage', () {
      tracker.recordUsage('textGeneration', 10.0);
      tracker.recordUsage('embeddings', 5.0);

      expect(tracker.getMethodUsage('textGeneration'), 10.0);
      expect(tracker.getMethodUsage('embeddings'), 5.0);
      expect(tracker.getGlobalUsage(), 15.0);
    });

    test('accumulates usage for same method', () {
      tracker.recordUsage('textGeneration', 10.0);
      tracker.recordUsage('textGeneration', 15.0);

      expect(tracker.getMethodUsage('textGeneration'), 25.0);
      expect(tracker.getGlobalUsage(), 25.0);
    });

    test('resets usage', () {
      tracker.recordUsage('textGeneration', 10.0);
      tracker.reset();

      expect(tracker.getGlobalUsage(), 0.0);
      expect(tracker.getMethodUsage('textGeneration'), 0.0);
    });
  });
}
