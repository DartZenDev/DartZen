import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import '../errors/ai_error.dart';
import '../models/ai_config.dart';
import '../models/ai_response.dart';

/// Budget enforcer for AI operations.
///
/// Tracks usage and enforces budget limits per method and globally.
@immutable
final class AIBudgetEnforcer {
  /// Creates a budget enforcer.
  const AIBudgetEnforcer({required this.config, required this.usageTracker});

  /// Budget configuration.
  final AIBudgetConfig config;

  /// Usage tracker.
  final AIUsageTracker usageTracker;

  /// Checks if a text generation request is within budget.
  ZenResult<void> checkTextGenerationBudget() =>
      _checkBudget(AIMethod.textGeneration, config.textGenerationLimit);

  /// Checks if an embeddings request is within budget.
  ZenResult<void> checkEmbeddingsBudget() =>
      _checkBudget(AIMethod.embeddings, config.embeddingsLimit);

  /// Checks if a classification request is within budget.
  ZenResult<void> checkClassificationBudget() =>
      _checkBudget(AIMethod.classification, config.classificationLimit);

  ZenResult<void> _checkBudget(AIMethod method, double? methodLimit) {
    // Check global budget first
    if (config.monthlyLimit != null) {
      final globalUsage = usageTracker.getGlobalUsage();
      final monthlyLimit = config.monthlyLimit!;
      if (globalUsage >= monthlyLimit) {
        return ZenResult.err(
          AIBudgetExceededError(limit: monthlyLimit, current: globalUsage),
        );
      }
    }

    // Check method-specific budget
    if (methodLimit != null) {
      final methodKey = _methodToKey(method);
      final methodUsage = usageTracker.getMethodUsage(methodKey);
      if (methodUsage >= methodLimit) {
        return ZenResult.err(
          AIBudgetExceededError(
            limit: methodLimit,
            current: methodUsage,
            method: methodKey,
          ),
        );
      }
    }

    return const ZenResult.ok(null);
  }

  /// Records usage for a request.
  void recordUsage(AIMethod method, double cost) {
    usageTracker.recordUsage(_methodToKey(method), cost);
  }

  static String _methodToKey(AIMethod method) {
    switch (method) {
      case AIMethod.textGeneration:
        return 'textGeneration';
      case AIMethod.embeddings:
        return 'embeddings';
      case AIMethod.classification:
        return 'classification';
    }
  }

  /// Calculates estimated cost (USD) for a given method and usage.
  ///
  /// This uses a simple, configurable per-method token pricing model.
  double calculateCost(AIMethod method, AIUsage usage, {String? model}) {
    // Rates are USD per token.
    const textInputRate = 0.00005; // per input token
    const textOutputRate = 0.00005; // per output token
    const embeddingsRate = 0.00025; // per input token (embeddings)
    const classificationRate = 0.00005; // per input token

    switch (method) {
      case AIMethod.textGeneration:
        return usage.inputTokens * textInputRate +
            usage.outputTokens * textOutputRate;
      case AIMethod.embeddings:
        return usage.inputTokens * embeddingsRate;
      case AIMethod.classification:
        return usage.inputTokens * classificationRate;
    }
  }
}

/// Methods supported by AI budget enforcement.
///
/// Use this enum when recording or checking usage so callers are
/// type-safe and resilient to renames.
enum AIMethod {
  /// Text generation requests (completion-like operations).
  textGeneration,

  /// Embeddings generation requests.
  embeddings,

  /// Classification requests.
  classification,
}

/// In-memory usage tracker used by the budget enforcer.
///
/// This implementation intentionally avoids an abstract interface since
/// the only supported storage is in-memory for tests and simple deployments.
final class AIUsageTracker {
  /// Creates an in-memory usage tracker.
  AIUsageTracker();

  final Map<String, double> _methodUsage = {};
  double _globalUsage = 0.0;

  /// Returns the current global usage (USD) across all methods.
  double getGlobalUsage() => _globalUsage;

  /// Returns the current usage (USD) for a specific method.
  double getMethodUsage(String method) => _methodUsage[method] ?? 0.0;

  /// Records `cost` (USD) against `method` and updates global usage.
  void recordUsage(String method, double cost) {
    _methodUsage[method] = (_methodUsage[method] ?? 0.0) + cost;
    _globalUsage += cost;
  }

  /// Resets all tracked usage. Useful for tests or monthly resets.
  void reset() {
    _methodUsage.clear();
    _globalUsage = 0.0;
  }
}
