import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  test('CacheConfig defaults and assigned values', () {
    const def = CacheConfig();
    expect(def.useTls, isTrue);
    expect(def.defaultTtl, isNull);
    expect(def.memorystoreHost, isNull);
    expect(def.memorystorePort, isNull);

    const c = CacheConfig(
      defaultTtl: Duration(minutes: 5),
      memorystoreHost: 'redis',
      memorystorePort: 6379,
      useTls: false,
    );

    expect(c.defaultTtl, equals(const Duration(minutes: 5)));
    expect(c.memorystoreHost, equals('redis'));
    expect(c.memorystorePort, equals(6379));
    expect(c.useTls, isFalse);
  });
}
