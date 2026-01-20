import 'dart:async';

import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:meta/meta.dart';

import '../models/ai_config.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../server/ai_service.dart';

/// AI task for text generation using Vertex AI / Gemini.
///
/// This task executes text generation via the AI service and is routed
/// through [ZenExecutor] with heavy weight classification.
///
/// ## Execution Model Compliance
///
/// AI calls are **inherently expensive**:
/// - Network-bound (calls to GCP Vertex AI)
/// - Latency-heavy (model inference time)
/// - Potentially long-running (complex prompts)
/// - Billable (GCP charges per token)
///
/// This task is classified as **heavy** and **slow** to ensure:
/// - It never blocks the event loop
/// - It is routed to the jobs system for cloud execution
/// - Budget enforcement happens before execution
///
/// ## Usage
///
/// ```dart
/// final task = TextGenerationAiTask(
///   prompt: 'Write a haiku about coding',
///   model: 'gemini-pro',
///   aiService: myAIService,
/// );
///
/// final result = await zenExecutor.execute(task);
/// ```
///
/// ## Assertion Guard
///
/// This task includes a runtime guard that ensures execution happens inside
/// a `ZenExecutor`-provided execution context (Zone). Heavy tasks must be
/// serializable via `toPayload()` so they can be dispatched to job workers.
@immutable
final class TextGenerationAiTask extends ZenTask<TextGenerationResponse> {
  /// Creates a text generation AI task.
  ///
  /// This constructor is intentionally data-only. Do NOT pass runtime
  /// service instances here. The executor/worker is responsible for
  /// providing an `AIService` implementation at execution time via the
  /// execution Zone (key: 'dartzen.ai.service').
  TextGenerationAiTask({
    required this.prompt,
    required this.model,
    this.config = const AIModelConfig(),
  });

  /// The prompt text.
  final String prompt;

  /// The model to use (e.g., 'gemini-pro').
  final String model;

  /// Model configuration.
  final AIModelConfig config;

  /// Returns a JSON-serializable payload for job envelopes.
  @override
  Map<String, dynamic> toPayload() => {
    'prompt': prompt,
    'model': model,
    'config': config.toJson(),
  };

  /// Reconstructs a task from a job payload.
  static TextGenerationAiTask fromPayload(Map<String, dynamic> payload) {
    final configJson = payload['config'] as Map<String, dynamic>? ?? {};
    return TextGenerationAiTask(
      prompt: payload['prompt'] as String? ?? '',
      model: payload['model'] as String? ?? '',
      config: AIModelConfig.fromJson(configJson),
    );
  }

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.heavy,
    latency: Latency.slow,
    retryable: true,
  );

  @override
  Future<TextGenerationResponse> execute() async {
    // Enforce executor-run context. `ZenExecutor` should run tasks inside a
    // Zone with `Zone.current['dartzen.executor'] == true` and provide an
    // `AIService` instance at `Zone.current['dartzen.ai.service']`.
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

  /// Internal runner that performs the business logic given a concrete
  /// `AIService` provided by the executor or worker.
  Future<TextGenerationResponse> _runWithService(AIService service) async {
    final request = TextGenerationRequest(
      prompt: prompt,
      model: model,
      config: config,
    );

    final result = await service.textGeneration(request);
    return result.fold((response) => response, (error) => throw error);
  }
}
