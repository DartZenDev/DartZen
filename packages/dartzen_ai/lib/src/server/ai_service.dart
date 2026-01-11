import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import '../models/ai_request.dart';
import '../models/ai_response.dart';
import 'ai_budget_enforcer.dart';
import 'vertex_ai_client.dart';

/// Main AI service for server-side operations.
///
/// Handles all Vertex AI / Gemini API calls with retry logic,
/// budget enforcement, and telemetry integration.
final class AIService {
  /// Creates an AI service.
  const AIService({
    required this.client,
    required this.budgetEnforcer,
    this.telemetryClient,
  });

  /// Vertex AI client.
  final VertexAIClient client;

  /// Budget enforcer.
  final AIBudgetEnforcer budgetEnforcer;

  /// Optional telemetry client.
  final TelemetryClient? telemetryClient;

  /// Generates text.
  Future<ZenResult<TextGenerationResponse>> textGeneration(
    TextGenerationRequest request,
  ) async {
    // Check budget
    final budgetCheck = budgetEnforcer.checkTextGenerationBudget();
    if (budgetCheck.isFailure) {
      await _emitTelemetry('ai.text_generation.budget_exceeded', {
        'model': request.model,
      });
      return ZenResult.err(budgetCheck.errorOrNull!);
    }

    // Make request with retry
    final result = await _withRetry<TextGenerationResponse>(
      () => client.generateText(request),
      maxAttempts: 3,
    );

    // Record usage and emit telemetry
    return result.fold(
      (response) {
        if (response.usage?.totalCost != null) {
          budgetEnforcer.recordUsage(
            'textGeneration',
            response.usage!.totalCost!,
          );
        }
        _emitTelemetry('ai.text_generation.success', {
          'model': request.model,
          'tokens': response.usage?.totalTokens ?? 0,
        });
        return ZenResult.ok(response);
      },
      (error) {
        _emitTelemetry('ai.text_generation.failure', {
          'model': request.model,
          'error': error.message,
        });
        return ZenResult.err(error);
      },
    );
  }

  /// Generates embeddings.
  Future<ZenResult<EmbeddingsResponse>> embeddings(
    EmbeddingsRequest request,
  ) async {
    // Check budget
    final budgetCheck = budgetEnforcer.checkEmbeddingsBudget();
    if (budgetCheck.isFailure) {
      await _emitTelemetry('ai.embeddings.budget_exceeded', {
        'model': request.model,
      });
      return ZenResult.err(budgetCheck.errorOrNull!);
    }

    // Make request with retry
    final result = await _withRetry<EmbeddingsResponse>(
      () => client.generateEmbeddings(request),
      maxAttempts: 3,
    );

    // Record usage and emit telemetry
    return result.fold(
      (response) {
        if (response.usage?.totalCost != null) {
          budgetEnforcer.recordUsage('embeddings', response.usage!.totalCost!);
        }
        _emitTelemetry('ai.embeddings.success', {
          'model': request.model,
          'count': request.texts.length,
        });
        return ZenResult.ok(response);
      },
      (error) {
        _emitTelemetry('ai.embeddings.failure', {
          'model': request.model,
          'error': error.message,
        });
        return ZenResult.err(error);
      },
    );
  }

  /// Classifies text.
  Future<ZenResult<ClassificationResponse>> classification(
    ClassificationRequest request,
  ) async {
    // Check budget
    final budgetCheck = budgetEnforcer.checkClassificationBudget();
    if (budgetCheck.isFailure) {
      await _emitTelemetry('ai.classification.budget_exceeded', {
        'model': request.model,
      });
      return ZenResult.err(budgetCheck.errorOrNull!);
    }

    // Make request with retry
    final result = await _withRetry(
      () => client.classify(request),
      maxAttempts: 3,
    );

    // Record usage and emit telemetry
    if (result.isFailure) {
      await _emitTelemetry('ai.classification.failure', {
        'model': request.model,
        'error': result.errorOrNull!.message,
      });
      return ZenResult.err(result.errorOrNull!);
    }

    final response = result.dataOrNull!;
    if (response.usage?.totalCost != null) {
      budgetEnforcer.recordUsage('classification', response.usage!.totalCost!);
    }
    await _emitTelemetry('ai.classification.success', {
      'model': request.model,
      'label': response.label,
    });
    return ZenResult.ok(response);
  }

  Future<ZenResult<T>> _withRetry<T>(
    Future<ZenResult<T>> Function() operation, {
    required int maxAttempts,
  }) async {
    var attempt = 0;
    while (attempt < maxAttempts) {
      final result = await operation();
      if (result.isSuccess) {
        return result;
      }

      attempt++;
      if (attempt < maxAttempts) {
        // Exponential backoff
        await Future<void>.delayed(
          Duration(milliseconds: 100 * (1 << attempt)),
        );
      } else {
        return result;
      }
    }
    throw StateError('Unreachable');
  }

  Future<void> _emitTelemetry(String name, Map<String, dynamic> payload) async {
    if (telemetryClient == null) return;

    final event = TelemetryEvent(
      name: name,
      timestamp: DateTime.now().toUtc(),
      scope: 'ai',
      source: TelemetrySource.server,
      payload: payload,
    );

    await telemetryClient!.emitEvent(event);
  }
}
