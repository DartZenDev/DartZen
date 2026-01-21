import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  setUp(ZenTransport.resetTestInstance);

  test('instance uses fromEnv and is a singleton', () async {
    // When no instance exists, `.instance` should create one using
    // `ZenTransportConfig.fromEnv()` which reflects `dzIsPrd`.
    final a = ZenTransport.instance;
    expect(a, isNotNull);
    expect(a.config.isProd, equals(dzIsPrd));

    // Subsequent calls return the same singleton.
    final b = ZenTransport.instance;
    expect(identical(a, b), isTrue);
  });

  test('factory sets explicit config (does not use fromEnv)', () async {
    // Provide an explicit config and ensure the transport exposes it.
    final t = ZenTransport(config: const ZenTransportConfig(isProd: true));
    expect(t.config.isProd, isTrue);
    // Also ensure the global instance references the created transport.
    expect(identical(ZenTransport.instance, t), isTrue);
  });
}
