import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import '../errors/ai_error.dart';
import '../models/ai_config.dart';

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
      _checkBudget('textGeneration', config.textGenerationLimit);

  /// Checks if an embeddings request is within budget.
  ZenResult<void> checkEmbeddingsBudget() =>
      _checkBudget('embeddings', config.embeddingsLimit);

  /// Checks if a classification request is within budget.
  ZenResult<void> checkClassificationBudget() =>
      _checkBudget('classification', config.classificationLimit);

  ZenResult<void> _checkBudget(String method, double? methodLimit) {
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
      final methodUsage = usageTracker.getMethodUsage(method);
      if (methodUsage >= methodLimit) {
        return ZenResult.err(
          AIBudgetExceededError(
            limit: methodLimit,
            current: methodUsage,
            method: method,
          ),
        );
      }
    }

    return const ZenResult.ok(null);
  }

  /// Records usage for a request.
  void recordUsage(String method, double cost) {
    usageTracker.recordUsage(method, cost);
  }
}

/// Tracks AI usage for budget enforcement.
abstract interface class AIUsageTracker {
  /// Gets global usage in USD.
  double getGlobalUsage();

  /// Gets method-specific usage in USD.
  double getMethodUsage(String method);

  /// Records usage.
  void recordUsage(String method, double cost);

  /// Resets usage (for testing or monthly reset).
  void reset();
}

/// In-memory usage tracker (for dev mode).
final class InMemoryUsageTracker implements AIUsageTracker {
  /// Creates an in-memory usage tracker.
  InMemoryUsageTracker();

  final Map<String, double> _methodUsage = {};
  double _globalUsage = 0.0;

  @override
  double getGlobalUsage() => _globalUsage;

  @override
  double getMethodUsage(String method) => _methodUsage[method] ?? 0.0;

  @override
  void recordUsage(String method, double cost) {
    _methodUsage[method] = (_methodUsage[method] ?? 0.0) + cost;
    _globalUsage += cost;
  }

  @override
  void reset() {
    _methodUsage.clear();
    _globalUsage = 0.0;
  }
}
