import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:http/http.dart' as http;

/// Minimal HTTP client for DartZen transport.
///
/// Automatically handles:
/// - Format negotiation via headers
/// - Request/response encoding/decoding
/// - Content-Type headers
///
/// Example:
/// ```dart
/// final client = ZenClient(baseUrl: 'http://localhost:8080');
/// final response = await client.post('/api/users', {'name': 'Alice'});
/// print(response['id']);
/// ```
class ZenClient {
  /// Creates a new ZenClient.
  ///
  /// [baseUrl] is the base URL for all requests.
  /// [format] specifies the transport format (defaults to JSON).
  /// [httpClient] allows injecting a custom HTTP client for testing.
  ZenClient({
    required this.baseUrl,
    this.format = ZenTransportFormat.json,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Base URL for all requests.
  final String baseUrl;

  /// Transport format to use.
  final ZenTransportFormat format;

  final http.Client _httpClient;

  /// Sends a GET request.
  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(headers),
    );
    return _decodeResponse(response);
  }

  /// Sends a POST request with data.
  Future<dynamic> post(
    String path,
    Object? data, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final body = ZenEncoder.encode(data, format);

    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(headers),
      body: body,
    );
    return _decodeResponse(response);
  }

  /// Sends a PUT request with data.
  Future<dynamic> put(
    String path,
    Object? data, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final body = ZenEncoder.encode(data, format);

    final response = await _httpClient.put(
      uri,
      headers: _buildHeaders(headers),
      body: body,
    );
    return _decodeResponse(response);
  }

  /// Sends a DELETE request.
  Future<dynamic> delete(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.delete(
      uri,
      headers: _buildHeaders(headers),
    );
    return _decodeResponse(response);
  }

  /// Closes the HTTP client.
  void close() => _httpClient.close();

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) => {
    'Content-Type': _contentType(format),
    zenTransportHeaderName: format.value,
    ...?customHeaders,
  };

  String _contentType(ZenTransportFormat format) {
    switch (format) {
      case ZenTransportFormat.json:
        return 'application/json';
      case ZenTransportFormat.msgpack:
        return 'application/msgpack';
    }
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return null;

    // Determine format from response header
    final responseFormat = response.headers[zenTransportHeaderName];
    final format = responseFormat != null
        ? ZenTransportFormat.parse(responseFormat)
        : this.format;

    return ZenDecoder.decode(Uint8List.fromList(response.bodyBytes), format);
  }
}
