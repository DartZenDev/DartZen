/// DartZen transport layer for serialization, codec selection, and WebSocket communication.
///
/// This package provides:
/// - JSON and MessagePack serialization
/// - Automatic codec selection based on environment and platform
/// - Transport envelopes (ZenRequest/ZenResponse)
/// - WebSocket helper with codec support
/// - Platform-aware treeshaking
/// - HTTP client wrapper
/// - Shelf middleware for server integration
///
/// ## Codec Selection
///
/// The package automatically selects the appropriate codec:
/// - **DEV mode**: JSON everywhere
/// - **PRD mode on web**: JSON
/// - **PRD mode on native**: MessagePack
///
/// You can override the default by specifying a format explicitly.
///
/// ## Client Usage
///
/// ```dart
/// final client = ZenClient(baseUrl: 'http://localhost:8080');
/// final response = await client.post('/api/users', {'name': 'Alice'});
/// print(response['id']);
/// ```
///
/// ## Server Usage
///
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(transportMiddleware())
///     .addHandler(_handleRequest);
///
/// Response _handleRequest(Request request) {
///   final data = {'message': 'Hello'};
///   return zenResponse(200, data);
/// }
/// ```
///
/// ## Protocol Usage
///
/// ```dart
/// // Create a request
/// final request = ZenRequest(
///   id: '123',
///   path: '/api/users',
///   data: {'name': 'John'},
/// );
///
/// // Encode using default codec
/// final bytes = request.encode();
///
/// // Decode response
/// final response = ZenResponse.decode(responseBytes);
///
/// // WebSocket usage
/// final ws = ZenWebSocket(Uri.parse('ws://localhost:8080'));
/// ws.send(request);
/// ws.responses.listen((response) {
///   print('Received: ${response.data}');
/// });
/// ```
library;

export 'src/client/zen_client.dart' show ZenClient, requestIdHeaderName;
export 'src/server/transport_middleware.dart'
    show transportMiddleware, zenResponse;
export 'src/zen_codec_selector.dart' show selectDefaultCodec;
export 'src/zen_decoder.dart' show ZenDecoder;
export 'src/zen_encoder.dart' show ZenEncoder;
export 'src/zen_message.dart' show ZenMessage;
export 'src/zen_request.dart' show ZenRequest;
export 'src/zen_response.dart' show ZenResponse;
export 'src/zen_transport_exception.dart' show ZenTransportException;
export 'src/zen_transport_header.dart'
    show ZenTransportFormat, zenTransportHeaderName;
export 'src/zen_websocket.dart' show ZenWebSocket;
