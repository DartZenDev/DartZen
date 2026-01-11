import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
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
  ///
  /// If [httpClient] is omitted, the client will create and own an
  /// internal `http.Client` instance which will be closed by [close()].
  VertexAIClient({
    required this.config,
    http.Client? httpClient,
    Future<String> Function()? accessTokenProvider,
    Future<auth.AccessCredentials> Function(
      auth.ServiceAccountCredentials,
      List<String>,
      http.Client,
    )?
    obtainAccessCredentials,
  }) : _client = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _accessTokenProvider = accessTokenProvider,
       _obtainAccessCredentials =
           obtainAccessCredentials ??
           auth.obtainAccessCredentialsViaServiceAccount;

  /// Service configuration.
  final AIServiceConfig config;

  final http.Client _client;
  final bool _ownsClient;
  final Future<String> Function()? _accessTokenProvider;
  final Future<auth.AccessCredentials> Function(
    auth.ServiceAccountCredentials,
    List<String>,
    http.Client,
  )
  _obtainAccessCredentials;

  String? _cachedAccessToken;
  DateTime? _cachedAccessTokenExpiry;

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
      final token = _accessTokenProvider != null
          ? await _accessTokenProvider()
          : await _getAccessToken();

      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'authorization': 'Bearer $token',
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
        // Respect Retry-After header if present
        final ra = response.headers['retry-after'];
        if (ra != null) {
          final seconds = int.tryParse(ra) ?? 0;
          return ZenResult.err(
            AIServiceUnavailableError(retryAfter: Duration(seconds: seconds)),
          );
        }
        return const ZenResult.err(
          AIQuotaExceededError(quotaType: 'rate_limit'),
        );
      } else if (response.statusCode >= 500) {
        final ra = response.headers['retry-after'];
        // Default to a short retry delay for server errors during tests.
        final seconds = ra != null ? int.tryParse(ra) ?? 1 : 1;
        return ZenResult.err(
          AIServiceUnavailableError(retryAfter: Duration(seconds: seconds)),
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

  /// Closes internal resources owned by this client.
  ///
  /// If the client was constructed with an externally-provided HTTP client,
  /// this will not close it (ownership remains with the caller).
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  // ignore: prefer_expression_function_bodies
  Future<String> _getAccessToken() async {
    // Dev mode: no credentials provided
    if (config.credentialsJson == null) return 'mock-access-token';

    // Return cached token when valid (with 30s safety margin)
    final now = DateTime.now().toUtc();
    if (_cachedAccessToken != null && _cachedAccessTokenExpiry != null) {
      if (now.isBefore(
        _cachedAccessTokenExpiry!.subtract(const Duration(seconds: 30)),
      )) {
        return _cachedAccessToken!;
      }
    }

    // In production: construct service account credentials and obtain
    // an OAuth2 access token scoped for cloud-platform, with caching.
    final Map<String, dynamic> jsonCreds =
        jsonDecode(config.credentialsJson!) as Map<String, dynamic>;
    final credentials = auth.ServiceAccountCredentials.fromJson(jsonCreds);
    const scopes = ['https://www.googleapis.com/auth/cloud-platform'];

    final client = http.Client();
    try {
      final access = await _obtainAccessCredentials(
        credentials,
        scopes,
        client,
      );
      _cachedAccessToken = access.accessToken.data;
      final expiry = access.accessToken.expiry;
      _cachedAccessTokenExpiry = expiry.toUtc();
      return _cachedAccessToken!;
    } finally {
      client.close();
    }
  }

  String _generateId() =>
      'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}
