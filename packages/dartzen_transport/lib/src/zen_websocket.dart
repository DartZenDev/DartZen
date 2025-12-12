import 'dart:async';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'zen_codec_selector.dart';
import 'zen_request.dart';
import 'zen_response.dart';
import 'zen_transport_header.dart';

/// A minimal WebSocket helper for DartZen transport.
///
/// Provides basic WebSocket connectivity with automatic codec selection
/// for sending [ZenRequest] and receiving [ZenResponse] messages.
///
/// This is a simple utility without reconnection or streaming logic.
class ZenWebSocket {
  /// Creates a WebSocket connection to the given [uri].
  ///
  /// Optionally specify a [format] to override automatic codec selection.
  ZenWebSocket(Uri uri, {ZenTransportFormat? format})
    : _format = format ?? selectDefaultCodec(),
      _channel = WebSocketChannel.connect(uri);

  final ZenTransportFormat _format;
  final WebSocketChannel _channel;

  /// The transport format being used.
  ZenTransportFormat get format => _format;

  /// Stream of incoming responses.
  Stream<ZenResponse> get responses => _channel.stream.map((message) {
    if (message is Uint8List) {
      return ZenResponse.decodeWith(message, _format);
    } else if (message is List<int>) {
      return ZenResponse.decodeWith(Uint8List.fromList(message), _format);
    } else {
      throw FormatException('Unexpected message type: ${message.runtimeType}');
    }
  });

  /// Sends a [request] through the WebSocket.
  void send(ZenRequest request) =>
      _channel.sink.add(request.encodeWith(_format));

  /// Closes the WebSocket connection.
  Future<void> close([int? closeCode, String? closeReason]) =>
      _channel.sink.close(closeCode, closeReason);
}
