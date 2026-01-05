import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:test/test.dart';

void main() {
  test('CacheOperationError toString contains operation', () {
    final err = CacheOperationError('op failed', 'set', cause: Exception('x'));
    final s = err.toString();

    expect(s, contains('CacheOperationError'));
    expect(s, contains('op failed'));
    expect(s, contains('operation: set'));
  });

  test('CacheSerializationError toString includes key', () {
    const err = CacheSerializationError('bad data', 'my-key');
    final s = err.toString();
    expect(s, contains('CacheSerializationError'));
    expect(s, contains('key: my-key'));
  });

  test('CacheConnectionError toString without cause', () {
    const err = CacheConnectionError('no network');
    final s = err.toString();
    expect(s, contains('CacheConnectionError'));
    expect(s, contains('no network'));
  });
}
