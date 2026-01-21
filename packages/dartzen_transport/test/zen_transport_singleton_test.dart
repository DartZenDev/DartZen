import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  setUp(ZenTransport.resetTestInstance);

  test('instance getter creates default instance from env', () {
    // Ensure no global instance is set
    ZenTransport.resetTestInstance();

    final inst = ZenTransport.instance;

    // The created instance should reflect compile-time env via dzIsPrd
    expect(inst.config.isProd, equals(dzIsPrd));
    // Subsequent calls return the same singleton
    expect(identical(ZenTransport.instance, inst), isTrue);
  });

  test('resetTestInstance clears singleton and instance recreated', () {
    const cfg = ZenTransportConfig(isProd: false);
    final first = ZenTransport(config: cfg);
    // factory should set global instance
    expect(identical(ZenTransport.instance, first), isTrue);

    ZenTransport.resetTestInstance();

    // After reset, a new instance is created by getter
    final recreated = ZenTransport.instance;
    expect(identical(recreated, first), isFalse);
  });
}
