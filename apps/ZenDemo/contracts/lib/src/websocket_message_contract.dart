/// Contract for WebSocket messages.
class WebSocketMessageContract {
  /// Creates a WebSocket message contract.
  const WebSocketMessageContract({
    required this.type,
    required this.payload,
  });

  /// Creates a WebSocket message contract from JSON.
  factory WebSocketMessageContract.fromJson(Map<String, dynamic> json) =>
      WebSocketMessageContract(
        type: json['type'] as String,
        payload: json['payload'] as String,
      );

  /// The message type (echo, status, error).
  final String type;

  /// The message payload.
  final String payload;

  /// Converts this contract to JSON.
  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
      };
}
