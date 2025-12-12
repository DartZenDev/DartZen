import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ZenTransportHeader', () {
    test('zenTransportHeaderName is correct', () {
      expect(zenTransportHeaderName, equals('X-DZ-Transport'));
    });

    test('ZenTransportFormat.json has correct value', () {
      expect(ZenTransportFormat.json.value, equals('json'));
    });

    test('ZenTransportFormat.msgpack has correct value', () {
      expect(ZenTransportFormat.msgpack.value, equals('msgpack'));
    });

    test('parses valid json format', () {
      final format = ZenTransportFormat.parse('json');
      expect(format, equals(ZenTransportFormat.json));
    });

    test('parses valid msgpack format', () {
      final format = ZenTransportFormat.parse('msgpack');
      expect(format, equals(ZenTransportFormat.msgpack));
    });

    test('parses case-insensitive values', () {
      expect(ZenTransportFormat.parse('JSON'), equals(ZenTransportFormat.json));
      expect(
        ZenTransportFormat.parse('MsgPack'),
        equals(ZenTransportFormat.msgpack),
      );
      expect(
        ZenTransportFormat.parse('MSGPACK'),
        equals(ZenTransportFormat.msgpack),
      );
    });

    test('throws on invalid format', () {
      expect(
        () => ZenTransportFormat.parse('xml'),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('throws on empty format', () {
      expect(
        () => ZenTransportFormat.parse(''),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('exception message is descriptive', () {
      try {
        ZenTransportFormat.parse('invalid');
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<ZenTransportException>());
        expect(e.toString(), contains('Invalid transport format: "invalid"'));
      }
    });
  });
}
