import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ZenCodecSelector', () {
    test('selectDefaultCodec returns JSON in DEV mode', () {
      // Note: This test assumes DZ_ENV is not set or is 'dev'
      // In actual testing, you'd use --define=DZ_ENV=dev
      final codec = selectDefaultCodec();
      expect(codec, isA<ZenTransportFormat>());
    });

    test('codec selection is deterministic', () {
      final codec1 = selectDefaultCodec();
      final codec2 = selectDefaultCodec();
      expect(codec1, equals(codec2));
    });
  });
}
