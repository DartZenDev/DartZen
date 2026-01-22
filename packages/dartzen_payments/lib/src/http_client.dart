import 'dart:convert';

import 'package:http/http.dart' as http;

import 'payment_http_response.dart';

/// Minimal HTTP client wrapper for payments providers.
abstract class PaymentsHttpClient {
  /// Sends a POST request to [path] with optional [body] and [headers].
  Future<PaymentHttpResponse> post(
    String path,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
  });

  /// Releases owned resources.
  void close();
}

/// Default implementation backed by `package:http`.
class DefaultPaymentsHttpClient implements PaymentsHttpClient {
  /// Creates a default payments HTTP client.
  DefaultPaymentsHttpClient({required String baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(baseUrl),
      _ownsClient = client == null;

  final http.Client _client;
  final Uri _baseUri;
  final bool _ownsClient;

  @override
  Future<PaymentHttpResponse> post(
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

    return PaymentHttpResponse(
      id:
          response.headers['x-request-id'] ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      statusCode: response.statusCode,
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
