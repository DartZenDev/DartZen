import 'package:meta/meta.dart';

import 'ai_config.dart';

/// Request for text generation.
@immutable
final class TextGenerationRequest {
  /// Creates a text generation request.
  const TextGenerationRequest({
    required this.prompt,
    required this.model,
    this.config = const AIModelConfig(),
    this.metadata,
  });

  /// The prompt text.
  final String prompt;

  /// The model to use (e.g., 'gemini-pro').
  final String model;

  /// Model configuration.
  final AIModelConfig config;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'model': model,
    'config': config.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Request for embeddings generation.
@immutable
final class EmbeddingsRequest {
  /// Creates an embeddings request.
  const EmbeddingsRequest({
    required this.texts,
    required this.model,
    this.metadata,
  });

  /// The texts to embed.
  final List<String> texts;

  /// The model to use (e.g., 'textembedding-gecko').
  final String model;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'texts': texts,
    'model': model,
    if (metadata != null) 'metadata': metadata,
  };
}

/// Request for classification.
@immutable
final class ClassificationRequest {
  /// Creates a classification request.
  const ClassificationRequest({
    required this.text,
    required this.model,
    this.labels,
    this.config = const AIModelConfig(),
    this.metadata,
  });

  /// The text to classify.
  final String text;

  /// The model to use.
  final String model;

  /// Optional list of labels for classification.
  final List<String>? labels;

  /// Model configuration.
  final AIModelConfig config;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'text': text,
    'model': model,
    if (labels != null) 'labels': labels,
    'config': config.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}
