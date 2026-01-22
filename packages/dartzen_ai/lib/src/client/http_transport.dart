import 'dart:convert';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:http/http.dart' as http;

/// Minimal HTTP client wrapper for AI transport.
abstract class AIHttpClient {
  /// Sends a POST request to [path] with optional [body] and [headers].
  Future<ZenResponse> post(
    String path,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
  });

  /// Releases any owned resources.
  void close();
}

/// Default HTTP implementation backed by `package:http`.
class DefaultAIHttpClient implements AIHttpClient {
  /// Creates a default AI HTTP client.
  DefaultAIHttpClient({required String baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(baseUrl),
      _ownsClient = client == null;

  final http.Client _client;
  final Uri _baseUri;
  final bool _ownsClient;

  @override
  Future<ZenResponse> post(
    String path,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
  }) async {
    final uri = _baseUri.resolve(path);
    final response = await _client.post(
      uri,
      headers: {
        'content-type': 'application/json',
        if (headers != null) ...headers,
      },
      body: body == null ? null : jsonEncode(body),
    );

    final parsed = _parseBody(response);

    return ZenResponse(
      id:
          response.headers['x-request-id'] ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      status: response.statusCode,
      data: parsed.data,
      error: parsed.error,
    );
  }

  _ParsedBody _parseBody(http.Response response) {
    if (response.body.isEmpty) {
      return const _ParsedBody();
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return _ParsedBody(data: decoded, error: decoded['error'] as String?);
      }
      return _ParsedBody(data: decoded);
    } catch (_) {
      return const _ParsedBody();
    }
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class _ParsedBody {
  const _ParsedBody({this.data, this.error});

  final Object? data;
  final String? error;
}
