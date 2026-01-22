import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import '../models/ai_request.dart';
import '../models/ai_response.dart';

/// Echo AI service for dev mode.
///
/// Returns mock responses structurally identical to Vertex AI
/// without making any GCP calls.
///
/// ## Internal API
///
/// This service is marked `@internal` and must NOT be used directly.
/// All AI operations must be executed via ZenTask subclasses routed
/// through ZenExecutor.
@internal
final class EchoAIService {
  /// Creates an Echo AI service.
  const EchoAIService();

  /// Generates text (echo mode).
  Future<ZenResult<TextGenerationResponse>> textGeneration(
    TextGenerationRequest request,
  ) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final response = TextGenerationResponse(
      text: 'Echo: ${request.prompt}',
      requestId: _generateId(),
      usage: const AIUsage(inputTokens: 10, outputTokens: 20),
      metadata: {'mode': 'echo', 'model': request.model},
    );

    return ZenResult.ok(response);
  }

  /// Generates embeddings (echo mode).
  Future<ZenResult<EmbeddingsResponse>> embeddings(
    EmbeddingsRequest request,
  ) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Generate mock embeddings (768-dimensional vectors)
    final embeddings = request.texts
        .map(
          (text) => List.generate(768, (i) => (text.hashCode + i) / 1000000.0),
        )
        .toList();

    final response = EmbeddingsResponse(
      embeddings: embeddings,
      requestId: _generateId(),
      usage: AIUsage(inputTokens: request.texts.length * 5, outputTokens: 0),
      metadata: {'mode': 'echo', 'model': request.model},
    );

    return ZenResult.ok(response);
  }

  /// Classifies text (echo mode).
  Future<ZenResult<ClassificationResponse>> classification(
    ClassificationRequest request,
  ) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Simple mock classification based on text length
    final label = request.text.length > 50 ? 'long' : 'short';
    const confidence = 0.85;

    final response = ClassificationResponse(
      label: label,
      confidence: confidence,
      requestId: _generateId(),
      allScores: {
        'long': label == 'long' ? confidence : 1.0 - confidence,
        'short': label == 'short' ? confidence : 1.0 - confidence,
      },
      usage: const AIUsage(inputTokens: 15, outputTokens: 5),
      metadata: {'mode': 'echo', 'model': request.model},
    );

    return ZenResult.ok(response);
  }

  String _generateId() =>
      'echo_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}
