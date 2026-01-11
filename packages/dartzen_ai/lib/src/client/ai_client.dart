import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_transport/dartzen_transport.dart';

import '../errors/ai_error.dart';
import '../models/ai_config.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import 'cancel_token.dart';

/// Flutter client for AI operations.
///
/// Communicates with server via dartzen_transport.
/// Supports cancellable requests via [CancelToken].
final class AIClient {
  /// Creates an AI client.
  AIClient({required String baseUrl, ZenClient? zenClient})
    : zenClient = zenClient ?? ZenClient(baseUrl: baseUrl);

  /// Transport client.
  final ZenClient zenClient;

  /// Generates text.
  Future<ZenResult<TextGenerationResponse>> textGeneration({
    required String prompt,
    required String model,
    AIModelConfig config = const AIModelConfig(),
    Map<String, dynamic>? metadata,
    CancelToken? cancelToken,
  }) async {
    final request = TextGenerationRequest(
      prompt: prompt,
      model: model,
      config: config,
      metadata: metadata,
    );

    return _makeRequest(
      endpoint: '/ai/text',
      body: request.toJson(),
      responseParser: TextGenerationResponse.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Generates embeddings.
  Future<ZenResult<EmbeddingsResponse>> embeddings({
    required List<String> texts,
    required String model,
    Map<String, dynamic>? metadata,
    CancelToken? cancelToken,
  }) async {
    final request = EmbeddingsRequest(
      texts: texts,
      model: model,
      metadata: metadata,
    );

    return _makeRequest(
      endpoint: '/ai/embeddings',
      body: request.toJson(),
      responseParser: EmbeddingsResponse.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Classifies text.
  Future<ZenResult<ClassificationResponse>> classification({
    required String text,
    required String model,
    List<String>? labels,
    AIModelConfig config = const AIModelConfig(),
    Map<String, dynamic>? metadata,
    CancelToken? cancelToken,
  }) async {
    final request = ClassificationRequest(
      text: text,
      model: model,
      labels: labels,
      config: config,
      metadata: metadata,
    );

    return _makeRequest(
      endpoint: '/ai/classification',
      body: request.toJson(),
      responseParser: ClassificationResponse.fromJson,
      cancelToken: cancelToken,
    );
  }

  Future<ZenResult<T>> _makeRequest<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) responseParser,
    CancelToken? cancelToken,
  }) async {
    // Check cancellation before making request
    if (cancelToken?.isCancelled ?? false) {
      return const ZenResult.err(AICancelledError());
    }

    try {
      final response = await zenClient.post(endpoint, body);

      // Check cancellation after request
      if (cancelToken?.isCancelled ?? false) {
        return const ZenResult.err(AICancelledError());
      }

      if (response.isSuccess) {
        if (response.data != null) {
          final parsed = responseParser(response.data as Map<String, dynamic>);
          return ZenResult.ok(parsed);
        } else {
          return ZenResult.err(
            const AIInvalidRequestError(reason: 'Empty response from server'),
          );
        }
      } else {
        // Parse error from server
        final error = _mapError(response);
        return ZenResult.err(error);
      }
    } catch (e) {
      // Network error - could be offline
      return ZenResult.err(
        const AIServiceUnavailableError(retryAfter: Duration(seconds: 30)),
      );
    }
  }

  AIError _mapError(ZenResponse response) {
    final errorCode = response.error ?? 'unknown';
    final data = response.data as Map<String, dynamic>?;
    final message = data?['message'] as String? ?? errorCode;

    if (errorCode.contains('budget_exceeded') || errorCode.contains('budget')) {
      return const AIBudgetExceededError(limit: 0, current: 0);
    } else if (errorCode.contains('quota')) {
      return const AIQuotaExceededError(quotaType: 'unknown');
    } else if (errorCode.contains('invalid') || response.status == 400) {
      return AIInvalidRequestError(reason: message);
    } else if (errorCode.contains('auth') ||
        response.status == 401 ||
        response.status == 403) {
      return AIAuthenticationError(reason: message);
    } else if (response.status >= 500) {
      return const AIServiceUnavailableError(retryAfter: Duration(seconds: 30));
    } else {
      return AIInvalidRequestError(reason: message);
    }
  }
}
