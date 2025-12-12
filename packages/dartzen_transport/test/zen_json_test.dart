import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('JSON Encoding/Decoding', () {
    test('encodes and decodes simple map', () {
      final data = {'name': 'John', 'age': 30};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.json);

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

      final bytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.json);

      expect(decoded, equals(data));
    });

    test('encodes and decodes null values', () {
      final data = {'value': null};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.json);

      expect(decoded, equals(data));
    });

    test('encodes and decodes arrays', () {
      final data = [1, 2, 3, 'four', true];
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.json);

      expect(decoded, equals(data));
    });

    test('handles empty map', () {
      final data = <String, dynamic>{};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.json);

      expect(decoded, equals(data));
    });

    test('handles unicode characters', () {
      final data = {'message': '你好世界 🌍'};
      final bytes = ZenEncoder.encode(data, ZenTransportFormat.json);
      final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.json);

      expect(decoded, equals(data));
    });
  });
}
