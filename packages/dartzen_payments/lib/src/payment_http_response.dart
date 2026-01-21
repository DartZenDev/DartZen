/// HTTP response type for payments operations.
///
/// This type represents an HTTP response from a payment provider.
/// It is used internally by the payments HTTP client to wrap provider responses
/// without depending on transport-specific types.
class PaymentHttpResponse {
  /// Creates an HTTP response.
  const PaymentHttpResponse({
    required this.id,
    required this.statusCode,
    this.data,
    this.error,
  });

  /// Unique identifier for the request/response pair.
  /// Typically from the 'x-request-id' header.
  final String id;

  /// HTTP status code (e.g., 200, 400, 500).
  final int statusCode;

  /// Optional response payload (usually decoded from JSON).
  final Object? data;

  /// Optional error message from the response.
  final String? error;

  /// Whether this response indicates success (status 200-299).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether this response indicates an error (status >= 400).
  bool get isError => statusCode >= 400;

  @override
  String toString() =>
      'PaymentHttpResponse(id: $id, statusCode: $statusCode, data: $data, error: $error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentHttpResponse &&
        other.id == id &&
        other.statusCode == statusCode &&
        _deepEquals(other.data, data) &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(id, statusCode, _deepHashCode(data), error);

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    return a == b;
  }

  static int _deepHashCode(Object? obj) {
    if (obj == null) return 0;
    if (obj is Map) {
      return Object.hashAll(
        obj.entries.map((e) => Object.hash(e.key, _deepHashCode(e.value))),
      );
    }
    return obj.hashCode;
  }
}
