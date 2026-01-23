import 'dart:math';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:meta/meta.dart';

import '../errors/ai_error.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import 'ai_budget_enforcer.dart';
import 'vertex_ai_client.dart';

/// Retry policy configuration for transient failures.
///
/// - `baseDelayMs`: initial backoff in milliseconds.
/// - `maxDelayMs`: maximum backoff cap in milliseconds.
/// - `jitterFactor`: fraction used to apply +/- jitter (0.0..1.0).
final class RetryPolicy {
  /// Creates a retry policy. Defaults to 100ms base delay, 5000ms max delay,
  /// and 0.5 jitter factor.
  const RetryPolicy({
    this.baseDelayMs = 100,
    this.maxDelayMs = 5000,
    this.jitterFactor = 0.5,
  });

  /// Base delay in milliseconds.
  final int baseDelayMs;

  /// Maximum delay in milliseconds.
  final int maxDelayMs;

  /// Jitter factor (0.0 to 1.0).
  final double jitterFactor;
}

/// Main AI service for server-side operations.
///
/// Handles all Vertex AI / Gemini API calls with retry logic,
/// budget enforcement, and telemetry integration.
///
/// ## Execution Model Compliance
///
/// This service is **fully non-blocking** and event-loop safe:
/// - All network calls are async and yield control
/// - Retry backoff uses `Future.delayed()` which is non-blocking
/// - No CPU-intensive synchronous work
/// - Budget checks are fast, in-memory operations
///
/// Retry delays do not block the event loop; they schedule
/// continuation on the event loop after the delay expires.
///
/// ## Internal API
///
/// This service is marked `@internal` and must NOT be used directly.
/// All AI operations must be executed via ZenTask subclasses routed
/// through ZenExecutor.
///
/// ## Telemetry Events
///
/// When a `TelemetryClient` is provided, the following events are emitted:
///
/// - `ai.textgeneration.success` — Text generation completed successfully.
///   Payload: `{ model, tokens }`.
/// - `ai.textgeneration.failure` — Text generation failed.
///   Payload: `{ model, error }`.
/// - `ai.textgeneration.budget.exceeded` — Budget check failed.
///   Payload: `{ model }`.
/// - `ai.embeddings.success` — Embeddings generated successfully.
///   Payload: `{ model, count }`.
/// - `ai.embeddings.failure` — Embeddings generation failed.
///   Payload: `{ model, error }`.
/// - `ai.embeddings.budget.exceeded` — Budget check failed.
///   Payload: `{ model }`.
/// - `ai.classification.success` — Classification completed successfully.
///   Payload: `{ model, label }`.
/// - `ai.classification.failure` — Classification failed.
///   Payload: `{ model, error }`.
/// - `ai.classification.budget.exceeded` — Budget check failed.
///   Payload: `{ model }`.
@internal
final class AIService {
  /// Creates an AI service.
  AIService({
    required this.client,
    required this.budgetEnforcer,
    this.telemetryClient,
    this.retryPolicy = const RetryPolicy(),
  });

  /// Vertex AI client.
  ///
  /// The client used to perform low-level calls to Vertex AI. Ownership is
  /// external by default; callers may pass a client they manage.
  final VertexAIClient client;

  /// Budget enforcer.
  ///
  /// Responsible for validating and recording usage against configured
  /// budget limits.
  final AIBudgetEnforcer budgetEnforcer;

  /// Optional telemetry client.
  ///
  /// When provided, usage and error telemetry events are emitted to this
  /// client.
  final TelemetryClient? telemetryClient;

  /// Retry policy used for transient failures.
  ///
  /// Configures backoff, cap and jitter for retry behavior.
  final RetryPolicy retryPolicy;

  /// Generates text.
  Future<ZenResult<TextGenerationResponse>> textGeneration(
    TextGenerationRequest request,
  ) async {
    // Check budget
    final budgetCheck = budgetEnforcer.checkTextGenerationBudget();
    if (budgetCheck.isFailure) {
      await _emitTelemetry('ai.textgeneration.budget.exceeded', {
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
        if (response.usage != null) {
          final cost = budgetEnforcer.calculateCost(
            AIMethod.textGeneration,
            response.usage!,
            model: request.model,
          );
          budgetEnforcer.recordUsage(AIMethod.textGeneration, cost);
        }
        _emitTelemetry('ai.textgeneration.success', {
          'model': request.model,
          'tokens': response.usage?.totalTokens ?? 0,
        });
        return ZenResult.ok(response);
      },
      (error) {
        _emitTelemetry('ai.textgeneration.failure', {
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
      await _emitTelemetry('ai.embeddings.budget.exceeded', {
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
        if (response.usage != null) {
          final cost = budgetEnforcer.calculateCost(
            AIMethod.embeddings,
            response.usage!,
            model: request.model,
          );
          budgetEnforcer.recordUsage(AIMethod.embeddings, cost);
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
      await _emitTelemetry('ai.classification.budget.exceeded', {
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
    if (response.usage != null) {
      final cost = budgetEnforcer.calculateCost(
        AIMethod.classification,
        response.usage!,
        model: request.model,
      );
      budgetEnforcer.recordUsage(AIMethod.classification, cost);
    }
    await _emitTelemetry('ai.classification.success', {
      'model': request.model,
      'label': response.label,
    });
    return ZenResult.ok(response);
  }

  /// Executes an operation with exponential backoff retry logic.
  ///
  /// ## Non-Blocking Guarantee
  ///
  /// Retry delays use `Future.delayed()`, which is async and non-blocking.
  /// The delay schedules continuation on the event loop without blocking
  /// other requests or operations.
  ///
  /// Retries only occur for transient failures. Non-retryable errors
  /// (authentication, invalid request, budget exceeded) return immediately.
  Future<ZenResult<T>> _withRetry<T>(
    Future<ZenResult<T>> Function() operation, {
    required int maxAttempts,
  }) async {
    final random = Random();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final result = await operation();
      if (result.isSuccess) return result;

      // Decide if error is retryable
      final error = result.errorOrNull;
      if (error is AIAuthenticationError ||
          error is AIInvalidRequestError ||
          error is AIBudgetExceededError) {
        // Non-retryable errors
        return result;
      }

      // If we've reached max attempts, return last result
      if (attempt == maxAttempts - 1) return result;

      // Honor explicit retry-after if provided by AIServiceUnavailableError
      Duration delay;
      if (error is AIServiceUnavailableError && error.retryAfter != null) {
        delay = error.retryAfter!;
      } else {
        // Exponential backoff with jitter using configured policy
        final exp = retryPolicy.baseDelayMs * (1 << attempt);
        final expCapped = exp.clamp(0, retryPolicy.maxDelayMs);
        final lower = (expCapped * (1 - retryPolicy.jitterFactor)).toInt();
        final upper = (expCapped * (1 + retryPolicy.jitterFactor)).toInt();
        final span = (upper - lower).clamp(1, upper);
        final ms = lower + random.nextInt(span);
        delay = Duration(milliseconds: ms);
      }

      await Future<void>.delayed(delay);
    }

    // Should be unreachable but return a sensible error
    return const ZenResult.err(
      AIServiceUnavailableError(retryAfter: Duration(seconds: 30)),
    );
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

  /// Closes owned resources used by this service.
  ///
  /// Note: this will close the underlying `VertexAIClient` if this service
  /// was constructed to own it. Owners of injected clients should manage
  /// their lifecycle themselves.
  Future<void> close() async {
    try {
      client.close();
    } catch (_) {
      // ignore
    }
  }
}
