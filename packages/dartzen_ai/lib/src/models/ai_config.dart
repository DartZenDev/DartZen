import 'package:meta/meta.dart';

/// Configuration for AI service.
///
/// This configuration is used server-side only and contains
/// GCP credentials and project information.
@immutable
final class AIServiceConfig {
  /// Creates an AI service configuration.
  const AIServiceConfig({
    required this.projectId,
    required this.region,
    required this.credentialsJson,
    this.budgetConfig = const AIBudgetConfig(),
  });

  /// Creates a dev mode configuration (no credentials required).
  const AIServiceConfig.dev({
    this.projectId = 'dev-project',
    this.region = 'us-central1',
    this.budgetConfig = const AIBudgetConfig.unlimited(),
  }) : credentialsJson = null;

  /// GCP project ID.
  final String projectId;

  /// GCP region for Vertex AI.
  final String region;

  /// GCP service account credentials JSON (server-side only).
  final String? credentialsJson;

  /// Budget configuration.
  final AIBudgetConfig budgetConfig;

  /// Whether this is a dev mode configuration.
  bool get isDev => credentialsJson == null;
}

/// Budget configuration for AI operations.
@immutable
final class AIBudgetConfig {
  /// Creates a budget configuration.
  const AIBudgetConfig({
    this.monthlyLimit,
    this.textGenerationLimit,
    this.embeddingsLimit,
    this.classificationLimit,
  });

  /// Creates an unlimited budget configuration.
  const AIBudgetConfig.unlimited()
    : monthlyLimit = null,
      textGenerationLimit = null,
      embeddingsLimit = null,
      classificationLimit = null;

  /// Global monthly budget limit in USD.
  final double? monthlyLimit;

  /// Per-method budget limit for text generation in USD.
  final double? textGenerationLimit;

  /// Per-method budget limit for embeddings in USD.
  final double? embeddingsLimit;

  /// Per-method budget limit for classification in USD.
  final double? classificationLimit;

  /// Whether this configuration has any limits.
  bool get hasLimits =>
      monthlyLimit != null ||
      textGenerationLimit != null ||
      embeddingsLimit != null ||
      classificationLimit != null;
}

/// Model configuration for AI operations.
@immutable
final class AIModelConfig {
  /// Creates a model configuration.
  const AIModelConfig({
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.topP = 0.95,
    this.topK = 40,
  });

  /// Temperature for sampling (0.0 to 1.0).
  final double temperature;

  /// Maximum number of tokens to generate.
  final int maxTokens;

  /// Top-p sampling parameter.
  final double topP;

  /// Top-k sampling parameter.
  final int topK;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'maxTokens': maxTokens,
    'topP': topP,
    'topK': topK,
  };
}
