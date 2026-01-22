import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:shelf/shelf.dart';

/// Public wrapper for transport middleware.
///
/// This middleware handles DartZen transport negotiation for server use.
/// It provides the same functionality as the internal transport middleware
/// but is explicitly available for framework server usage.
Middleware zenServerTransportMiddleware() =>
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
Response zenServerResponse(
  int statusCode,
  Object? data, {
  Map<String, String>? headers,
}) => Response(
  statusCode,
  headers: headers,
  context: data != null ? {'zen_data': data} : {},
);
