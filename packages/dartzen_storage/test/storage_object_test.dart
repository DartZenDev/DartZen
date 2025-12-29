import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:test/test.dart';

void main() {
  group('StorageObject', () {
    test('creates object with bytes and content type', () {
      final bytes = [72, 101, 108, 108, 111];
      final object = StorageObject(bytes: bytes, contentType: 'text/plain');

      expect(object.bytes, equals(bytes));
      expect(object.contentType, equals('text/plain'));
      expect(object.size, equals(5));
    });

    test('creates object without content type', () {
      final bytes = [72, 101, 108, 108, 111];
      final object = StorageObject(bytes: bytes);

      expect(object.contentType, isNull);
      expect(object.size, equals(5));
    });

    test('converts bytes to string', () {
      const bytes = [72, 101, 108, 108, 111];
      const object = StorageObject(bytes: bytes);

      expect(object.asString(), equals('Hello'));
    });

    test('toString returns formatted string', () {
      const object = StorageObject(
        bytes: [1, 2, 3],
        contentType: 'application/json',
      );

      expect(
        object.toString(),
        equals('StorageObject(size: 3, contentType: application/json)'),
      );
    });
  });
}
