import 'package:dartzen_ui_admin/src/admin/zen_admin_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZenAdminPage', () {
    test('creates with provided values', () {
      const page = ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '1', 'name': 'Alice'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      );
      expect(page.items.length, 1);
      expect(page.total, 1);
      expect(page.offset, 0);
      expect(page.limit, 20);
    });

    test('empty items list', () {
      const page = ZenAdminPage<String>(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      );
      expect(page.items, isEmpty);
      expect(page.total, 0);
    });

    test('equality for same values', () {
      const a = ZenAdminPage<String>(
        items: ['a', 'b'],
        total: 2,
        offset: 0,
        limit: 20,
      );
      const b = ZenAdminPage<String>(
        items: ['a', 'b'],
        total: 2,
        offset: 0,
        limit: 20,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different items', () {
      const a = ZenAdminPage<String>(
        items: ['a'],
        total: 1,
        offset: 0,
        limit: 20,
      );
      const b = ZenAdminPage<String>(
        items: ['b'],
        total: 1,
        offset: 0,
        limit: 20,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality for different total', () {
      const a = ZenAdminPage<String>(
        items: ['a'],
        total: 1,
        offset: 0,
        limit: 20,
      );
      const b = ZenAdminPage<String>(
        items: ['a'],
        total: 5,
        offset: 0,
        limit: 20,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality for different offset', () {
      const a = ZenAdminPage<String>(
        items: ['a'],
        total: 1,
        offset: 0,
        limit: 20,
      );
      const b = ZenAdminPage<String>(
        items: ['a'],
        total: 1,
        offset: 10,
        limit: 20,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality for different limit', () {
      const a = ZenAdminPage<String>(
        items: ['a'],
        total: 1,
        offset: 0,
        limit: 20,
      );
      const b = ZenAdminPage<String>(
        items: ['a'],
        total: 1,
        offset: 0,
        limit: 50,
      );
      expect(a, isNot(equals(b)));
    });

    test('toString contains type and counts', () {
      const page = ZenAdminPage<int>(
        items: [1, 2, 3],
        total: 10,
        offset: 0,
        limit: 20,
      );
      final str = page.toString();
      expect(str, contains('ZenAdminPage<int>'));
      expect(str, contains('items: 3'));
      expect(str, contains('total: 10'));
    });

    test('generic type is preserved', () {
      const page = ZenAdminPage<int>(
        items: [42],
        total: 1,
        offset: 0,
        limit: 20,
      );
      expect(page.items.first, isA<int>());
    });

    test('is not equal to non-ZenAdminPage', () {
      const page = ZenAdminPage<String>(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      );
      expect(page, isNot(equals('not a page')));
    });
  });
}
