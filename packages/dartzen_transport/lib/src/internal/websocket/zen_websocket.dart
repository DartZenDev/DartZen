import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../zen_codec_selector.dart';
import '../../zen_request.dart';
import '../../zen_response.dart';
import '../../zen_transport_header.dart';

/// A minimal WebSocket helper for DartZen transport.
///
/// **INTERNAL USE ONLY:** This class must only be used within ZenTask execution
/// via ZenExecutor. Direct instantiation and use outside of tasks is not
/// supported and violates the package's architecture.
///
/// Provides basic WebSocket connectivity with automatic codec selection
/// for sending [ZenRequest] and receiving [ZenResponse] messages.
///
/// This is a simple utility without reconnection or streaming logic.
@internal
class ZenWebSocket {
  /// Creates a WebSocket connection to the given [uri].
  ///
  /// Optionally specify a [format] to override automatic codec selection.
  ZenWebSocket(Uri uri, {ZenTransportFormat? format})
    : _format = format ?? selectDefaultCodec(),
      _channel = WebSocketChannel.connect(uri);

  /// Alternative constructor that accepts an existing [WebSocketChannel].
  ///
  /// Useful for tests or when a channel is created externally and should be
  /// injected into the `ZenWebSocket` helper.
  @visibleForTesting
  ZenWebSocket.withChannel(
    WebSocketChannel channel, {
    ZenTransportFormat? format,
  }) : _format = format ?? selectDefaultCodec(),
       _channel = channel;

  final ZenTransportFormat _format;
  final WebSocketChannel _channel;

  /// The transport format being used.
  ZenTransportFormat get format => _format;

  /// Stream of incoming responses.
  Stream<ZenResponse> get responses => _channel.stream.map(
    (message) => _mapMessageToResponseInternal(message, _format),
  );

  /// Internal mapping logic for a single WebSocket message to a `ZenResponse`.
  /// Centralized so production code and tests share the same implementation.
  static ZenResponse _mapMessageToResponseInternal(
    dynamic message,
    ZenTransportFormat format,
  ) {
    if (message is Uint8List) return ZenResponse.decodeWith(message, format);
    if (message is List<int>) {
      return ZenResponse.decodeWith(Uint8List.fromList(message), format);
    }
    throw FormatException('Unexpected message type: ${message.runtimeType}');
  }

  /// Test-visible thin wrapper around internal mapping logic.
  ///
  /// Marked `@visibleForTesting` to make clear this API exists for tests
  /// and should not be treated as a stable public contract by consumers.
  @visibleForTesting
  static ZenResponse mapMessageToResponse(
    dynamic message,
    ZenTransportFormat format,
  ) => _mapMessageToResponseInternal(message, format);

  /// Sends a [request] through the WebSocket.
  void send(ZenRequest request) =>
      _channel.sink.add(request.encodeWith(_format));

  /// Closes the WebSocket connection.
  Future<void> close([int? closeCode, String? closeReason]) =>
      _channel.sink.close(closeCode, closeReason);
}
