import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/src/firestore_types.dart';
import 'package:test/test.dart';

void main() {
  group('ZenFirestoreDocument', () {
    test('exists returns true when data is not null', () {
      const doc = ZenFirestoreDocument(
        id: 'test-id',
        path: 'test/path',
        data: {'field': 'value'},
      );

      expect(doc.exists, isTrue);
    });

    test('exists returns false when data is null', () {
      const doc = ZenFirestoreDocument(id: 'test-id', path: 'test/path');

      expect(doc.exists, isFalse);
    });

    test('constructor accepts all parameters', () {
      final createTime = ZenTimestamp.now();
      final updateTime = ZenTimestamp.now();

      final doc = ZenFirestoreDocument(
        id: 'test-id',
        path: 'test/path',
        data: {'field': 'value'},
        createTime: createTime,
        updateTime: updateTime,
      );

      expect(doc.id, equals('test-id'));
      expect(doc.path, equals('test/path'));
      expect(doc.data, equals({'field': 'value'}));
      expect(doc.createTime, equals(createTime));
      expect(doc.updateTime, equals(updateTime));
      expect(doc.exists, isTrue);
    });

    test('constructor with minimal parameters', () {
      const doc = ZenFirestoreDocument(id: 'test-id', path: 'test/path');

      expect(doc.id, equals('test-id'));
      expect(doc.path, equals('test/path'));
      expect(doc.data, isNull);
      expect(doc.createTime, isNull);
      expect(doc.updateTime, isNull);
      expect(doc.exists, isFalse);
    });
  });
}
