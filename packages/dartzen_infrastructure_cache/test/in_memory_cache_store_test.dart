import 'package:dartzen_infrastructure_cache/dartzen_infrastructure_cache.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryCacheStore store;

  setUp(() {
    store = InMemoryCacheStore();
  });

  group('InMemoryCacheStore', () {
    test('get should return null if key does not exist', () async {
      final result = await store.get('missing');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('set and get should work for string', () async {
      await store.set('key1', 'value1', const Duration(minutes: 5));
      final result = await store.get('key1');
      expect(result.dataOrNull, 'value1');
    });

    test('get should return null if expired', () async {
      await store.set('key1', 'value1', const Duration(milliseconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final result = await store.get('key1');
      expect(result.dataOrNull, isNull);
    });

    test('delete should remove key', () async {
      await store.set('key1', 'value1', const Duration(minutes: 5));
      await store.delete('key1');
      final result = await store.get('key1');
      expect(result.dataOrNull, isNull);
    });
  });
}
