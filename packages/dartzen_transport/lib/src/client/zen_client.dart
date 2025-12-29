import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../zen_decoder.dart';
import '../zen_encoder.dart';
import '../zen_response.dart';
import '../zen_transport_header.dart';

/// Standard HTTP header for request IDs.
const String requestIdHeaderName = 'X-Request-ID';

/// Minimal HTTP client for DartZen transport.
///
/// Automatically handles:
/// - Format negotiation via headers
/// - Request/response encoding/decoding
/// - Content-Type headers
/// - HTTP status code propagation
///
/// All methods return [ZenResponse] objects that include:
/// - HTTP status code
/// - Response body (decoded)
/// - Error information (if applicable)
///
/// Example:
/// ```dart
/// final client = ZenClient(baseUrl: 'http://localhost:8080');
/// final response = await client.post('/api/users', {'name': 'Alice'});
/// if (response.isSuccess) {
///   print(response.data['id']);
/// } else {
///   print('Error: ${response.error}');
/// }
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
  int _requestCounter = 0;

  /// Generates a unique request ID.
  String _generateRequestId() {
    _requestCounter++;
    return 'req-${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }

  /// Sends a GET request.
  ///
  /// Returns a [ZenResponse] containing the status code and decoded body.
  Future<ZenResponse> get(String path, {Map<String, String>? headers}) async {
    final requestId = _generateRequestId();
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(headers, requestId),
    );
    return _buildZenResponse(response, requestId);
  }

  /// Sends a POST request with data.
  ///
  /// Returns a [ZenResponse] containing the status code and decoded body.
  Future<ZenResponse> post(
    String path,
    Object? data, {
    Map<String, String>? headers,
  }) async {
    final requestId = _generateRequestId();
    final uri = Uri.parse('$baseUrl$path');
    final body = ZenEncoder.encode(data, format);

    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(headers, requestId),
      body: body,
    );
    return _buildZenResponse(response, requestId);
  }

  /// Sends a PUT request with data.
  ///
  /// Returns a [ZenResponse] containing the status code and decoded body.
  Future<ZenResponse> put(
    String path,
    Object? data, {
    Map<String, String>? headers,
  }) async {
    final requestId = _generateRequestId();
    final uri = Uri.parse('$baseUrl$path');
    final body = ZenEncoder.encode(data, format);

    final response = await _httpClient.put(
      uri,
      headers: _buildHeaders(headers, requestId),
      body: body,
    );
    return _buildZenResponse(response, requestId);
  }

  /// Sends a DELETE request.
  ///
  /// Returns a [ZenResponse] containing the status code and decoded body.
  Future<ZenResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final requestId = _generateRequestId();
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.delete(
      uri,
      headers: _buildHeaders(headers, requestId),
    );
    return _buildZenResponse(response, requestId);
  }

  /// Closes the HTTP client.
  void close() => _httpClient.close();

  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders,
    String requestId,
  ) => {
    'Content-Type': _contentType(format),
    zenTransportHeaderName: format.value,
    requestIdHeaderName: requestId,
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

  ZenResponse _buildZenResponse(http.Response response, String requestId) {
    final statusCode = response.statusCode;
    final isError = statusCode >= 400;

    // Decode body if present
    Object? decodedData;
    if (response.body.isNotEmpty) {
      try {
        final responseFormat = response.headers[zenTransportHeaderName];
        final format = responseFormat != null
            ? ZenTransportFormat.parse(responseFormat)
            : this.format;

        decodedData = ZenDecoder.decode(
          Uint8List.fromList(response.bodyBytes),
          format,
        );
      } catch (_) {
        // If decoding fails, treat as error
        decodedData = null;
      }
    }

    // Extract error message if this is an error response
    String? errorMessage;
    if (isError) {
      if (decodedData is Map && decodedData.containsKey('error')) {
        errorMessage = decodedData['error']?.toString();
      } else if (decodedData is Map && decodedData.containsKey('message')) {
        errorMessage = decodedData['message']?.toString();
      } else {
        errorMessage = response.reasonPhrase;
      }
    }

    return ZenResponse(
      id: requestId,
      status: statusCode,
      data: decodedData,
      error: errorMessage,
    );
  }
}
