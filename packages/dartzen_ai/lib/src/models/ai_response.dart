import 'package:meta/meta.dart';

/// Response from text generation.
@immutable
final class TextGenerationResponse {
  /// Creates a text generation response.
  const TextGenerationResponse({
    required this.text,
    required this.requestId,
    this.usage,
    this.metadata,
  });

  /// Creates from JSON map.
  factory TextGenerationResponse.fromJson(Map<String, dynamic> json) =>
      TextGenerationResponse(
        text: json['text'] as String,
        requestId: json['requestId'] as String,
        usage: json['usage'] != null
            ? AIUsage.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// The generated text.
  final String text;

  /// The request ID.
  final String requestId;

  /// Usage information.
  final AIUsage? usage;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'text': text,
    'requestId': requestId,
    if (usage != null) 'usage': usage!.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Response from embeddings generation.
@immutable
final class EmbeddingsResponse {
  /// Creates an embeddings response.
  const EmbeddingsResponse({
    required this.embeddings,
    required this.requestId,
    this.usage,
    this.metadata,
  });

  /// Creates from JSON map.
  factory EmbeddingsResponse.fromJson(Map<String, dynamic> json) =>
      EmbeddingsResponse(
        embeddings: (json['embeddings'] as List<dynamic>)
            .map((e) => (e as List<dynamic>).cast<double>())
            .toList(),
        requestId: json['requestId'] as String,
        usage: json['usage'] != null
            ? AIUsage.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// The generated embeddings (one per input text).
  final List<List<double>> embeddings;

  /// The request ID.
  final String requestId;

  /// Usage information.
  final AIUsage? usage;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'embeddings': embeddings,
    'requestId': requestId,
    if (usage != null) 'usage': usage!.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Response from classification.
@immutable
final class ClassificationResponse {
  /// Creates a classification response.
  const ClassificationResponse({
    required this.label,
    required this.confidence,
    required this.requestId,
    this.allScores,
    this.usage,
    this.metadata,
  });

  /// Creates from JSON map.
  factory ClassificationResponse.fromJson(Map<String, dynamic> json) =>
      ClassificationResponse(
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        requestId: json['requestId'] as String,
        allScores: json['allScores'] != null
            ? (json['allScores'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              )
            : null,
        usage: json['usage'] != null
            ? AIUsage.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// The predicted label.
  final String label;

  /// Confidence score (0.0 to 1.0).
  final double confidence;

  /// The request ID.
  final String requestId;

  /// All classification scores (label -> score).
  final Map<String, double>? allScores;

  /// Usage information.
  final AIUsage? usage;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'requestId': requestId,
    if (allScores != null) 'allScores': allScores,
    if (usage != null) 'usage': usage!.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Usage information for AI requests.
@immutable
final class AIUsage {
  /// Creates usage information.
  const AIUsage({required this.inputTokens, required this.outputTokens});

  /// Creates from JSON map.
  factory AIUsage.fromJson(Map<String, dynamic> json) => AIUsage(
    inputTokens: json['inputTokens'] as int,
    outputTokens: json['outputTokens'] as int,
  );

  /// Number of input tokens.
  final int inputTokens;

  /// Number of output tokens.
  final int outputTokens;

  /// No cost field here; cost is computed by the budget enforcer.

  /// Total tokens.
  int get totalTokens => inputTokens + outputTokens;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
  };
}
