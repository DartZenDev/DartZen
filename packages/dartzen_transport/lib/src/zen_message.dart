import 'dart:typed_data';

import 'zen_codec_selector.dart';
import 'zen_decoder.dart';
import 'zen_encoder.dart';
import 'zen_transport_header.dart';

/// Base class for transport messages.
///
/// Provides serialization and deserialization capabilities using
/// the appropriate codec based on environment and platform.
abstract class ZenMessage {
  /// Creates a message.
  const ZenMessage();

  /// Converts this message to a map for serialization.
  Map<String, dynamic> toMap();

  /// Encodes this message to bytes using the default codec.
  Uint8List encode() => encodeWith(selectDefaultCodec());

  /// Encodes this message to bytes using the specified [format].
  Uint8List encodeWith(ZenTransportFormat format) =>
      ZenEncoder.encode(toMap(), format);

  /// Decodes bytes to a map using the default codec.
  static Map<String, dynamic> decode(Uint8List bytes) =>
      decodeWith(bytes, selectDefaultCodec());

  /// Decodes bytes to a map using the specified [format].
  static Map<String, dynamic> decodeWith(
    Uint8List bytes,
    ZenTransportFormat format,
  ) {
    final decoded = ZenDecoder.decode(bytes, format);
    if (decoded is! Map) {
      throw FormatException('Expected Map, got ${decoded.runtimeType}');
    }
    // Cast to Map<String, dynamic> to handle MessagePack's dynamic maps
    return Map<String, dynamic>.from(decoded);
  }
}
