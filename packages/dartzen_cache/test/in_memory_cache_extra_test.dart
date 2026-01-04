import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  test('entries expire when TTL elapses', () async {
    final cache = InMemoryCache();

    await cache.set('temp', 'v', ttl: const Duration(milliseconds: 20));
    final v1 = await cache.get<String>('temp');
    expect(v1, equals('v'));

    // Wait for expiry
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final v2 = await cache.get<String>('temp');
    expect(v2, isNull);
  });

  test('setting non-serializable value throws CacheSerializationError', () async {
    final cache = InMemoryCache();
    expect(
      () => cache.set('k', () => 'fn'),
      throwsA(isA<CacheSerializationError>()),
    );
  });

  test('type mismatch on get throws CacheSerializationError', () async {
    final cache = InMemoryCache();
    // store a string value
    await cache.set('k', '123');

    // requesting as int should throw
    expect(
      () => cache.get<int>('k'),
      throwsA(isA<CacheSerializationError>()),
    );
  });
}
