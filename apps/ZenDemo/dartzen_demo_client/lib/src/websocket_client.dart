import 'dart:convert';

import 'package:dartzen_demo_contracts/dartzen_demo_contracts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket client for ZenDemo.
class ZenDemoWebSocketClient {
  /// Creates a [ZenDemoWebSocketClient].
  ZenDemoWebSocketClient({required this.wsUrl});

  /// WebSocket URL.
  final String wsUrl;
  WebSocketChannel? _channel;

  /// Stream of incoming WebSocket messages.
  Stream<WebSocketMessageContract>? get messages =>
      _channel?.stream.map((dynamic data) {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        return WebSocketMessageContract.fromJson(json);
      });

  /// Connects to the WebSocket server.
  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  /// Sends a [message] through the WebSocket.
  void send(WebSocketMessageContract message) {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  /// Disconnects from the WebSocket server.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  /// Whether the client is currently connected.
  bool get isConnected => _channel != null;
}
