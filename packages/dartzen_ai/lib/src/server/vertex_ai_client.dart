import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

import '../errors/ai_error.dart';
import '../models/ai_config.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';

/// Low-level Vertex AI REST API client.
///
/// Handles direct API calls to Google's Vertex AI service for text generation,
/// embeddings, and classification.
/// Low-level Vertex AI REST API client.
///
/// Handles authentication, request construction, and response parsing.

final class VertexAIClient {
  /// Creates a Vertex AI client.
  const VertexAIClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient;

  /// Service configuration.
  final AIServiceConfig config;

  final http.Client? _httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  /// Generates text using Vertex AI.
  Future<ZenResult<TextGenerationResponse>> generateText(
    TextGenerationRequest request,
  ) async {
    try {
      final url = _buildUrl('generateText');
      final response = await _post(url, request.toJson());

      return response.fold((data) {
        final text = data['text'] as String? ?? '';
        final requestId = data['requestId'] as String? ?? _generateId();
        final usage = data['usage'] != null
            ? AIUsage.fromJson(data['usage'] as Map<String, dynamic>)
            : null;

        return ZenResult.ok(
          TextGenerationResponse(
            text: text,
            requestId: requestId,
            usage: usage,
            metadata: data['metadata'] as Map<String, dynamic>?,
          ),
        );
      }, ZenResult.err);
    } catch (e) {
      return const ZenResult.err(
        AIServiceUnavailableError(retryAfter: Duration(seconds: 30)),
      );
    }
  }

  /// Generates embeddings using Vertex AI.
  Future<ZenResult<EmbeddingsResponse>> generateEmbeddings(
    EmbeddingsRequest request,
  ) async {
    try {
      final url = _buildUrl('generateEmbeddings');
      final response = await _post(url, request.toJson());

      return response.fold((data) {
        final embeddings =
            (data['embeddings'] as List<dynamic>?)
                ?.map((e) => (e as List<dynamic>).cast<double>())
                .toList() ??
            [];
        final requestId = data['requestId'] as String? ?? _generateId();
        final usage = data['usage'] != null
            ? AIUsage.fromJson(data['usage'] as Map<String, dynamic>)
            : null;

        return ZenResult.ok(
          EmbeddingsResponse(
            embeddings: embeddings,
            requestId: requestId,
            usage: usage,
            metadata: data['metadata'] as Map<String, dynamic>?,
          ),
        );
      }, ZenResult.err);
    } catch (e) {
      return const ZenResult.err(
        AIServiceUnavailableError(retryAfter: Duration(seconds: 30)),
      );
    }
  }

  /// Classifies text using Vertex AI.
  Future<ZenResult<ClassificationResponse>> classify(
    ClassificationRequest request,
  ) async {
    try {
      final url = _buildUrl('classify');
      final response = await _post(url, request.toJson());

      return response.fold((data) {
        final label = data['label'] as String? ?? 'unknown';
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        final requestId = data['requestId'] as String? ?? _generateId();
        final usage = data['usage'] != null
            ? AIUsage.fromJson(data['usage'] as Map<String, dynamic>)
            : null;

        return ZenResult.ok(
          ClassificationResponse(
            label: label,
            confidence: confidence,
            requestId: requestId,
            allScores: data['allScores'] != null
                ? (data['allScores'] as Map<String, dynamic>).map(
                    (k, v) => MapEntry(k, (v as num).toDouble()),
                  )
                : null,
            usage: usage,
            metadata: data['metadata'] as Map<String, dynamic>?,
          ),
        );
      }, ZenResult.err);
    } catch (e) {
      return const ZenResult.err(
        AIServiceUnavailableError(retryAfter: Duration(seconds: 30)),
      );
    }
  }

  String _buildUrl(String endpoint) =>
      'https://${config.region}-aiplatform.googleapis.com/v1/projects/${config.projectId}/locations/${config.region}/$endpoint';

  Future<ZenResult<Map<String, dynamic>>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAccessToken()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ZenResult.ok(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return const ZenResult.err(
          AIAuthenticationError(reason: 'Invalid credentials'),
        );
      } else if (response.statusCode == 429) {
        return const ZenResult.err(
          AIQuotaExceededError(quotaType: 'rate_limit'),
        );
      } else if (response.statusCode >= 500) {
        return const ZenResult.err(
          AIServiceUnavailableError(retryAfter: Duration(seconds: 60)),
        );
      } else {
        return ZenResult.err(
          AIInvalidRequestError(
            reason: 'HTTP ${response.statusCode}: ${response.body}',
          ),
        );
      }
    } catch (e) {
      return const ZenResult.err(
        AIServiceUnavailableError(retryAfter: Duration(seconds: 30)),
      );
    }
  }

  // ignore: prefer_expression_function_bodies
  Future<String> _getAccessToken() async {
    // In production, this would use GCP service account credentials
    // to obtain an access token. For now, return a placeholder.
    // Real implementation would use package:googleapis_auth
    return 'mock-access-token';
  }

  String _generateId() =>
      'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}
