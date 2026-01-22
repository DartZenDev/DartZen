import 'package:dartzen_ai/src/errors/ai_error.dart';
import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/models/ai_response.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:test/test.dart';

void main() {
  group('AIBudgetEnforcer', () {
    test('blocks when global monthly limit exceeded', () {
      final tracker = AIUsageTracker();
      // record some usage that exceeds the monthly limit
      tracker.recordUsage('textGeneration', 100.0);

      final config = AIBudgetConfig(monthlyLimit: 50.0);
      final enforcer = AIBudgetEnforcer(config: config, usageTracker: tracker);

      final result = enforcer.checkTextGenerationBudget();
      expect(result.isFailure, isTrue);
      final err = result.errorOrNull as AIBudgetExceededError;
      expect(err, isA<AIBudgetExceededError>());
      expect(err.limit, equals(50.0));
      expect(err.current, equals(100.0));
    });

    test('blocks when per-method limit exceeded', () {
      final tracker = AIUsageTracker();
      tracker.recordUsage('embeddings', 5.0);

      final config = AIBudgetConfig(embeddingsLimit: 1.0);
      final enforcer = AIBudgetEnforcer(config: config, usageTracker: tracker);

      final result = enforcer.checkEmbeddingsBudget();
      expect(result.isFailure, isTrue);
      final err = result.errorOrNull as AIBudgetExceededError;
      expect(err, isA<AIBudgetExceededError>());
      expect(err.limit, equals(1.0));
      expect(err.current, equals(5.0));
    });

    test('calculateCost returns expected values', () {
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: AIUsageTracker(),
      );

      const textUsage = AIUsage(inputTokens: 10, outputTokens: 5);
      final textCost = enforcer.calculateCost(
        AIMethod.textGeneration,
        textUsage,
      );
      expect(textCost, closeTo(0.00075, 1e-9));

      const embedUsage = AIUsage(inputTokens: 20, outputTokens: 0);
      final embedCost = enforcer.calculateCost(AIMethod.embeddings, embedUsage);
      expect(embedCost, closeTo(0.005, 1e-9));

      const classUsage = AIUsage(inputTokens: 4, outputTokens: 0);
      final classCost = enforcer.calculateCost(
        AIMethod.classification,
        classUsage,
      );
      expect(classCost, closeTo(0.0002, 1e-9));
    });

    test('recordUsage updates tracker and reset clears it', () {
      final tracker = AIUsageTracker();
      final enforcer = AIBudgetEnforcer(
        config: const AIBudgetConfig.unlimited(),
        usageTracker: tracker,
      );

      enforcer.recordUsage(AIMethod.classification, 0.42);
      expect(tracker.getGlobalUsage(), equals(0.42));
      expect(tracker.getMethodUsage('classification'), equals(0.42));

      tracker.reset();
      expect(tracker.getGlobalUsage(), equals(0.0));
      expect(tracker.getMethodUsage('classification'), equals(0.0));
    });
  });
}
