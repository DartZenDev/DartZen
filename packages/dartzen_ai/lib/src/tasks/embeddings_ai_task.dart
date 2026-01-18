// ignore_for_file: prefer_expression_function_bodies

import 'dart:async';

import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:meta/meta.dart';

import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../server/ai_service.dart';

/// AI task for embeddings generation using Vertex AI.
///
/// This task is data-only and serializable. The executor or worker must
/// inject an `AIService` via the execution Zone under
/// `Zone.current['dartzen.ai.service']` before invoking the task.
@immutable
final class EmbeddingsAiTask extends ZenTask<EmbeddingsResponse> {
  /// Creates an embeddings generation AI task.
  EmbeddingsAiTask({required this.texts, required this.model});

  /// The texts to embed.
  final List<String> texts;

  /// The model to use (e.g., 'textembedding-gecko').
  final String model;

  /// Returns a JSON-serializable payload for job envelopes.
  @override
  Map<String, dynamic> toPayload() => {'texts': texts, 'model': model};

  /// Reconstructs a task from a job payload.
  static EmbeddingsAiTask fromPayload(Map<String, dynamic> payload) {
    final texts = (payload['texts'] as List<dynamic>?)?.cast<String>() ?? [];
    return EmbeddingsAiTask(
      texts: texts,
      model: payload['model'] as String? ?? '',
    );
  }

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.heavy,
    latency: Latency.slow,
    retryable: true,
  );

  @override
  Future<EmbeddingsResponse> execute() async {
    if (Zone.current['dartzen.executor'] != true) {
      throw StateError(
        'AI tasks MUST be executed via ZenExecutor.execute(), not directly. '
        'Ensure the executor runs the task within the expected Zone.',
      );
    }

    final dynamic svc = Zone.current['dartzen.ai.service'];
    if (svc == null || svc is! AIService) {
      throw StateError(
        'AIService not found in execution context. The executor must inject an AIService instance '
        'into Zone.current["dartzen.ai.service"] before invoking the task.',
      );
    }

    return _runWithService(svc);
  }

  Future<EmbeddingsResponse> _runWithService(AIService service) async {
    final request = EmbeddingsRequest(texts: texts, model: model);
    final result = await service.embeddings(request);
    return result.fold((response) => response, (error) => throw error);
  }
}
