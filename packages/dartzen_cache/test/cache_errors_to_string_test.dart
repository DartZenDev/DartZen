import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  test('CacheConnectionError toString without cause', () {
    const err = CacheConnectionError('no network');
    final s = err.toString();
    expect(s, contains('CacheConnectionError'));
    expect(s, contains('no network'));
  });
}
