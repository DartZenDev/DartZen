import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('MessagePack Encoding/Decoding', () {
    test('encodes and decodes simple map', () {
      final data = {'name': 'John', 'age': 30};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);

      expect(decoded, equals(data));
    });

    test('encodes and decodes nested structures', () {
      final data = {
        'user': {
          'name': 'Alice',
          'roles': ['admin', 'user'],
        },
        'timestamp': 1234567890,
      };

      final bytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);

      expect(decoded, equals(data));
    });

    test('encodes and decodes null values', () {
      final data = {'value': null};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);

      expect(decoded, equals(data));
    });

    test('encodes and decodes arrays', () {
      final data = [1, 2, 3, 'four', true];
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);

      expect(decoded, equals(data));
    });

    test('handles empty map', () {
      final data = <String, dynamic>{};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);

      expect(decoded, equals(data));
    });

    test('handles binary data efficiently', () {
      final data = {
        'binary': Uint8List.fromList([1, 2, 3, 4, 5]),
        'text': 'hello',
      };

      final bytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);
      final decoded =
          ZenDecoder.decode(bytes, ZenTransportFormat.msgpack) as Map;

      expect(decoded['text'], equals('hello'));
      expect(decoded['binary'], isA<List<dynamic>>());
    });

    test('MessagePack is more compact than JSON for binary data', () {
      final data = {'data': List.generate(100, (i) => i)};

      final jsonBytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final msgpackBytes = ZenEncoder.encode(data, ZenTransportFormat.msgpack);

      // MessagePack should be more compact
      expect(msgpackBytes.length, lessThan(jsonBytes.length));
    });
  });
}
