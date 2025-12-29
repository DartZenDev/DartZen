import 'dart:convert';
import 'dart:typed_data';

import 'codecs/msgpack_encoder.dart' as msgpack;
import 'zen_transport_exception.dart';
import 'zen_transport_header.dart';

/// Encodes data to bytes using the specified format.
///
/// Supports JSON and MessagePack encoding.
/// Throws [ZenTransportException] if encoding fails.
class ZenEncoder {
  const ZenEncoder._();

  /// Encodes [data] using the specified [format].
  ///
  /// For JSON: converts to JSON string then UTF-8 bytes.
  /// For MessagePack: serializes directly to binary format.
  ///
  /// Throws [ZenTransportException] if encoding fails.
  static Uint8List encode(Object? data, ZenTransportFormat format) {
    try {
      switch (format) {
        case ZenTransportFormat.json:
          return _encodeJson(data);
        case ZenTransportFormat.msgpack:
          return _encodeMsgpack(data);
      }
    } catch (e) {
      throw ZenTransportException('Failed to encode data: $e');
    }
  }

  static Uint8List _encodeJson(Object? data) =>
      Uint8List.fromList(utf8.encode(jsonEncode(data)));

  static Uint8List _encodeMsgpack(Object? data) => msgpack.encodeValue(data);
}
