import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  test('defaultTtl is applied when ttl is omitted', () async {
    final cache = InMemoryCache(defaultTtl: const Duration(milliseconds: 20));

    await cache.set('k', 'v');
    final v1 = await cache.get<String>('k');
    expect(v1, equals('v'));

    await Future<void>.delayed(const Duration(milliseconds: 40));
    final v2 = await cache.get<String>('k');
    expect(v2, isNull);
  });
}
