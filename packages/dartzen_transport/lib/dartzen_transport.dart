/// DartZen transport layer for serialization and protocol abstraction.
///
/// This package provides foundational transport abstractions and serialization
/// utilities for DartZen applications. All external I/O (HTTP, gRPC, WebSocket,
/// etc.) **must be performed through tasks executed via ZenExecutor**.
///
/// ## Architecture
///
/// **IMPORTANT:** Direct network access from user code is prohibited. All
/// transport operations must execute within a ZenTask via ZenExecutor.
/// This includes:
///
/// - ❌ Direct HTTP calls using ZenClient
/// - ❌ WebSocket connections outside of tasks
/// - ❌ Server setup without framework integration
///
/// The package provides task-safe APIs for:
/// - Protocol abstraction (ZenRequest, ZenResponse)
/// - Serialization and codec selection
/// - Error handling and exceptions
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
/// ```
///
/// ## ZenExecutor Integration
///
/// Define transport operations as tasks:
///
/// ```dart
/// class GetUserTask extends ZenTask<User> {
///   GetUserTask(this.userId);
///   final String userId;
///
///   @override
///   Future<User> execute() async {
///     // HTTP call happens here, inside execute()
///     // Framework manages the client and connection
///   }
/// }
///
/// // Execute the task
/// final user = await zen.execute(GetUserTask('123'));
/// ```
library;

export 'src/config.dart' show ZenTransportConfig;
export 'src/descriptors.dart'
    show
        TransportDescriptor,
        TransportChannel,
        TransportReliability,
        TransportResult;
export 'src/zen_codec_selector.dart' show selectDefaultCodec;
export 'src/zen_decoder.dart' show ZenDecoder;
export 'src/zen_encoder.dart' show ZenEncoder;
export 'src/zen_message.dart' show ZenMessage;
export 'src/zen_request.dart' show ZenRequest;
export 'src/zen_response.dart' show ZenResponse;
export 'src/zen_transport.dart' show ZenTransport;
export 'src/zen_transport_exception.dart' show ZenTransportException;
export 'src/zen_transport_header.dart'
    show ZenTransportFormat, zenTransportHeaderName;
