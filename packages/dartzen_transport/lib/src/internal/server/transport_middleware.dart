import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../../zen_decoder.dart';
import '../../zen_encoder.dart';
import '../../zen_transport_header.dart';

/// Creates Shelf middleware for DartZen transport negotiation.
///
/// **INTERNAL USE ONLY:** This middleware must only be used within server
/// contexts that are managed by ZenExecutor or similar frameworks. Direct
/// server setup using this middleware outside of framework context is not
/// supported and violates the package's architecture.
///
/// Automatically handles:
/// - Content-Type negotiation
/// - X-DZ-Transport header parsing
/// - Request/response encoding/decoding
///
/// Example (for internal framework use only):
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(transportMiddleware())
///     .addHandler(_handleRequest);
/// ```
@internal
Middleware transportMiddleware() =>
    (Handler innerHandler) => (Request request) async {
      // Determine format from header or default
      final format = _negotiateFormat(request);

      // Decode request body if present
      final bodyBytes = await request.read().fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );

      // Store decoded data in request context
      final decodedData = bodyBytes.isEmpty
          ? null
          : ZenDecoder.decode(Uint8List.fromList(bodyBytes), format);

      final updatedRequest = request.change(
        context: {
          ...request.context,
          'transport_format': format,
          'decoded_data': decodedData,
        },
      );

      // Call inner handler
      final response = await innerHandler(updatedRequest);

      // Encode response body if needed
      if (response.context.containsKey('zen_data')) {
        final data = response.context['zen_data'];
        final responseBytes = ZenEncoder.encode(data, format);

        return Response(
          response.statusCode,
          body: responseBytes,
          headers: {
            ...response.headers,
            'Content-Type': _contentType(format),
            zenTransportHeaderName: format.value,
          },
        );
      }

      return response;
    };

ZenTransportFormat _negotiateFormat(Request request) {
  final header = request.headers[zenTransportHeaderName];

  if (header != null) {
    try {
      return ZenTransportFormat.parse(header);
    } catch (_) {
      // Invalid header, fall back to default
    }
  }

  // Check Content-Type
  final contentType = request.headers['content-type'];
  if (contentType != null) {
    if (contentType.contains('application/msgpack')) {
      return ZenTransportFormat.msgpack;
    }
    if (contentType.contains('application/json')) {
      return ZenTransportFormat.json;
    }
  }

  // Default to JSON
  return ZenTransportFormat.json;
}

String _contentType(ZenTransportFormat format) {
  switch (format) {
    case ZenTransportFormat.json:
      return 'application/json';
    case ZenTransportFormat.msgpack:
      return 'application/msgpack';
  }
}

/// Helper to create a response with encoded data.
///
/// **INTERNAL USE ONLY:** This function is for framework/internal use only.
///
/// Example (for internal framework use only):
/// ```dart
/// Response _handleRequest(Request request) {
///   final data = {'message': 'Hello'};
///   return zenResponse(200, data);
/// }
/// ```
@internal
Response zenResponse(
  int statusCode,
  Object? data, {
  Map<String, String>? headers,
}) => Response(
  statusCode,
  headers: headers,
  context: data != null ? {'zen_data': data} : {},
);
