import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  test('CacheFactory selects backend based on dzIsPrd', () {
    const cfg = CacheConfig(defaultTtl: Duration(minutes: 1));

    if (dzIsPrd) {
      // In production missing host/port should throw
      expect(() => CacheFactory.create(cfg), throwsArgumentError);

      // valid production config returns MemorystoreCache
      const good = CacheConfig(
        defaultTtl: Duration(minutes: 1),
        memorystoreHost: 'h',
        memorystorePort: 6379,
      );
      final client = CacheFactory.create(good);
      expect(client, isA<MemorystoreCache>());
    } else {
      final client = CacheFactory.create(cfg);
      expect(client, isA<InMemoryCache>());
    }
  });

  test('Production requires both host and port', () {
    if (!dzIsPrd) return;

    expect(
      () => CacheFactory.create(const CacheConfig(memorystoreHost: '', memorystorePort: 6379)),
      throwsArgumentError,
    );

    expect(
      () => CacheFactory.create(const CacheConfig(memorystoreHost: 'h')),
      throwsArgumentError,
    );
  });
}
