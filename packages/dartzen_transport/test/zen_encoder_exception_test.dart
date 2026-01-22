import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  test('ZenEncoder throws ZenTransportException on circular JSON', () {
    final map = <String, dynamic>{};
    map['self'] = map; // create circular reference

    expect(
      () => ZenEncoder.encode(map, ZenTransportFormat.json),
      throwsA(isA<ZenTransportException>()),
    );
  });
}
