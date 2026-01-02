/// Contract for ping server endpoint.
class PingContract {
  /// Creates a ping contract.
  const PingContract({
    required this.message,
    required this.timestamp,
  });

  /// Creates a ping contract from JSON.
  factory PingContract.fromJson(Map<String, dynamic> json) => PingContract(
        message: json['message'] as String,
        timestamp: json['timestamp'] as String,
      );

  /// The ping message.
  final String message;

  /// The timestamp when the ping was created.
  final String timestamp;

  /// Converts this contract to JSON.
  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp,
      };
}
