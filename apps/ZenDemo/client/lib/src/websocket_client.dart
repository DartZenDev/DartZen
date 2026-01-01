import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

/// WebSocket client for ZenDemo.
class ZenDemoWebSocketClient {
  ZenDemoWebSocketClient({required this.wsUrl});

  final String wsUrl;
  WebSocketChannel? _channel;

  Stream<WebSocketMessageContract>? get messages =>
      _channel?.stream.map((dynamic data) {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        return WebSocketMessageContract.fromJson(json);
      });

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  void send(WebSocketMessageContract message) {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _channel != null;
}
