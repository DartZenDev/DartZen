import 'dart:convert';

import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

class _FakeCache implements CacheClient {
  final Map<String, Object?> _m = {};

  @override
  Future<void> clear() async {
    _m.clear();
  }

  @override
  Future<void> delete(String key) async {
    _m.remove(key);
  }

  @override
  Future<T?> get<T>(String key) async {
    final v = _m[key];
    if (v == null) return null;
    if (v is T) return v as T;
    final enc = jsonEncode(v);
    final dec = jsonDecode(enc);
    if (dec is! T) throw CacheSerializationError('type mismatch', key);
    return dec;
  }

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    // validate serializability
    jsonEncode(value);
    _m[key] = value;
  }
}

void main() {
  test('FakeCache implements CacheClient behavior', () async {
    final c = _FakeCache();
    expect(await c.get<dynamic>('x'), isNull);

    await c.set('x', {'a': 1});
    final v = await c.get<Map<String, dynamic>>('x');
    expect(v, equals({'a': 1}));

    await c.delete('x');
    expect(await c.get<dynamic>('x'), isNull);

    await c.set('a', '1');
    await c.clear();
    expect(await c.get<dynamic>('a'), isNull);
  });

  test(
    'FakeCache get with type mismatch throws CacheSerializationError',
    () async {
      final c = _FakeCache();
      await c.set('k', '123');
      expect(() => c.get<int>('k'), throwsA(isA<CacheSerializationError>()));
    },
  );
}
