// ignore_for_file: prefer_expression_function_bodies

import 'dart:async';

import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:meta/meta.dart';

import '../models/ai_config.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../server/ai_service.dart';

/// AI task for text classification using Vertex AI / Gemini.
///
/// This task is data-only and serializable. The executor or worker must
/// inject an `AIService` via the execution Zone under
/// `Zone.current['dartzen.ai.service']` before invoking the task.
@immutable
final class ClassificationAiTask extends ZenTask<ClassificationResponse> {
  /// Creates a text classification AI task.
  ClassificationAiTask({
    required this.text,
    required this.model,
    this.labels,
    this.config = const AIModelConfig(),
  });

  /// The text to classify.
  final String text;

  /// The model to use (e.g., 'gemini-pro').
  final String model;

  /// Optional classification labels.
  final List<String>? labels;

  /// Model configuration.
  final AIModelConfig config;

  /// Returns a JSON-serializable payload for job envelopes.
  @override
  Map<String, dynamic> toPayload() => {
    'text': text,
    'model': model,
    if (labels != null) 'labels': labels,
    'config': config.toJson(),
  };

  /// Reconstructs a task from a job payload.
  static ClassificationAiTask fromPayload(Map<String, dynamic> payload) {
    return ClassificationAiTask(
      text: payload['text'] as String? ?? '',
      model: payload['model'] as String? ?? '',
      labels: (payload['labels'] as List<dynamic>?)?.cast<String>(),
      config: payload['config'] != null
          ? AIModelConfig.fromJson(payload['config'] as Map<String, dynamic>)
          : const AIModelConfig(),
    );
  }

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.heavy,
    latency: Latency.slow,
    retryable: true,
  );

  @override
  Future<ClassificationResponse> execute() async {
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

  Future<ClassificationResponse> _runWithService(AIService service) async {
    final request = ClassificationRequest(
      text: text,
      model: model,
      labels: labels,
      config: config,
    );

    final result = await service.classification(request);
    return result.fold((response) => response, (error) => throw error);
  }
}
