import 'dart:typed_data';

import 'zen_message.dart';
import 'zen_transport_header.dart';

/// Represents a request message in the DartZen transport protocol.
///
/// A request contains:
/// - [id]: Unique identifier for request/response correlation
/// - [path]: The endpoint or action path
/// - [data]: Optional payload data
class ZenRequest extends ZenMessage {
  /// Creates a request with the given [id], [path], and optional [data].
  const ZenRequest({required this.id, required this.path, this.data});

  /// Unique identifier for this request.
  final String id;

  /// The endpoint or action path.
  final String path;

  /// Optional request payload.
  final Object? data;

  @override
  Map<String, dynamic> toMap() => {'id': id, 'path': path, 'data': data};

  /// Creates a [ZenRequest] from a map.
  factory ZenRequest.fromMap(Map<String, dynamic> map) => ZenRequest(
    id: map['id'] as String,
    path: map['path'] as String,
    data: map['data'],
  );

  /// Decodes bytes to a [ZenRequest] using the default codec.
  static ZenRequest decode(Uint8List bytes) {
    final map = ZenMessage.decode(bytes);
    return ZenRequest.fromMap(map);
  }

  /// Decodes bytes to a [ZenRequest] using the specified [format].
  static ZenRequest decodeWith(Uint8List bytes, ZenTransportFormat format) {
    final map = ZenMessage.decodeWith(bytes, format);
    return ZenRequest.fromMap(map);
  }

  @override
  String toString() => 'ZenRequest(id: $id, path: $path, data: $data)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenRequest &&
        other.id == id &&
        other.path == path &&
        _deepEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(id, path, _deepHashCode(data));

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
