import 'dart:typed_data';

import 'zen_message.dart';
import 'zen_transport_header.dart';

/// Represents a response message in the DartZen transport protocol.
///
/// A response contains:
/// - [id]: Unique identifier matching the corresponding request
/// - [status]: HTTP-style status code
/// - [data]: Optional response payload
/// - [error]: Optional error message
class ZenResponse extends ZenMessage {
  /// Creates a response with the given [id], [status], optional [data], and [error].
  const ZenResponse({
    required this.id,
    required this.status,
    this.data,
    this.error,
  });

  /// Unique identifier matching the request.
  final String id;

  /// HTTP-style status code (e.g., 200, 404, 500).
  final int status;

  /// Optional response payload.
  final Object? data;

  /// Optional error message.
  final String? error;

  /// Whether this response indicates success (status 200-299).
  bool get isSuccess => status >= 200 && status < 300;

  /// Whether this response indicates an error (status >= 400).
  bool get isError => status >= 400;

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'status': status,
    'data': data,
    'error': error,
  };

  /// Creates a [ZenResponse] from a map.
  factory ZenResponse.fromMap(Map<String, dynamic> map) => ZenResponse(
    id: map['id'] as String,
    status: map['status'] as int,
    data: map['data'],
    error: map['error'] as String?,
  );

  /// Decodes bytes to a [ZenResponse] using the default codec.
  static ZenResponse decode(Uint8List bytes) {
    final map = ZenMessage.decode(bytes);
    return ZenResponse.fromMap(map);
  }

  /// Decodes bytes to a [ZenResponse] using the specified [format].
  static ZenResponse decodeWith(Uint8List bytes, ZenTransportFormat format) {
    final map = ZenMessage.decodeWith(bytes, format);
    return ZenResponse.fromMap(map);
  }

  @override
  String toString() =>
      'ZenResponse(id: $id, status: $status, data: $data, error: $error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenResponse &&
        other.id == id &&
        other.status == status &&
        _deepEquals(other.data, data) &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(id, status, _deepHashCode(data), error);

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
