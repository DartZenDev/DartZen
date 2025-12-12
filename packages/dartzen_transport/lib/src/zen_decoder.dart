import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_msgpack/dartzen_msgpack.dart' as msgpack;

import 'zen_transport_exception.dart';
import 'zen_transport_header.dart';

/// Decodes bytes to data using the specified format.
///
/// Supports JSON and MessagePack decoding.
/// Throws [ZenTransportException] if decoding fails.
class ZenDecoder {
  const ZenDecoder._();

  /// Decodes [bytes] using the specified [format].
  ///
  /// For JSON: converts UTF-8 bytes to string then parses JSON.
  /// For MessagePack: deserializes directly from binary format.
  ///
  /// Throws [ZenTransportException] if decoding fails.
  static Object? decode(Uint8List bytes, ZenTransportFormat format) {
    try {
      switch (format) {
        case ZenTransportFormat.json:
          return _decodeJson(bytes);
        case ZenTransportFormat.msgpack:
          return _decodeMsgpack(bytes);
      }
    } catch (e) {
      throw ZenTransportException('Failed to decode data: $e');
    }
  }

  static Object? _decodeJson(Uint8List bytes) => jsonDecode(utf8.decode(bytes));

  static Object? _decodeMsgpack(Uint8List bytes) => msgpack.decode(bytes);
}
