import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:test/test.dart';

class DummyReader implements ZenStorageReader {
  @override
  Future<StorageObject?> read(String key) async {
    if (key == 'exists') {
      return const StorageObject(bytes: [1, 2, 3], contentType: 'text/plain');
    }
    return null;
  }
}

void main() {
  group('ZenStorageReader', () {
    test('returns object when found', () async {
      final reader = DummyReader();
      final obj = await reader.read('exists');
      expect(obj, isNotNull);
      expect(obj!.bytes, equals([1, 2, 3]));
      expect(obj.contentType, 'text/plain');
    });

    test('returns null when not found', () async {
      final reader = DummyReader();
      final obj = await reader.read('missing');
      expect(obj, isNull);
    });
  });
}
