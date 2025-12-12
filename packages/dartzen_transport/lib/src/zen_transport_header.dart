import 'zen_transport_exception.dart';

/// The header name used for transport format negotiation.
const String zenTransportHeaderName = 'X-DZ-Transport';

/// Valid transport format values.
enum ZenTransportFormat {
  /// JSON format.
  json('json'),

  /// MessagePack format.
  msgpack('msgpack');

  const ZenTransportFormat(this.value);

  /// The string value used in headers.
  final String value;

  /// Parses a header value into a [ZenTransportFormat].
  ///
  /// Throws [ZenTransportException] if the value is invalid.
  static ZenTransportFormat parse(String value) {
    switch (value.toLowerCase()) {
      case 'json':
        return ZenTransportFormat.json;
      case 'msgpack':
        return ZenTransportFormat.msgpack;
      default:
        throw ZenTransportException(
          'Invalid transport format: "$value". Expected "json" or "msgpack".',
        );
    }
  }
}
