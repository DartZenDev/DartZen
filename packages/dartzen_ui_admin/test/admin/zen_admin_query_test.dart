import 'package:dartzen_ui_admin/src/admin/zen_admin_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZenAdminQuery', () {
    test('defaults offset to 0 and limit to 20', () {
      const query = ZenAdminQuery();
      expect(query.offset, 0);
      expect(query.limit, 20);
    });

    test('accepts explicit values', () {
      const query = ZenAdminQuery(offset: 10, limit: 50);
      expect(query.offset, 10);
      expect(query.limit, 50);
    });

    test('assert fires for negative offset', () {
      expect(() => ZenAdminQuery(offset: -1), throwsA(isA<AssertionError>()));
    });

    test('assert fires for negative limit', () {
      expect(() => ZenAdminQuery(limit: -1), throwsA(isA<AssertionError>()));
    });

    test('allows zero offset and zero limit', () {
      const query = ZenAdminQuery(offset: 0, limit: 0);
      expect(query.offset, 0);
      expect(query.limit, 0);
    });

    test('equality for same values', () {
      const a = ZenAdminQuery(offset: 5, limit: 10);
      const b = ZenAdminQuery(offset: 5, limit: 10);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different offset', () {
      const a = ZenAdminQuery(offset: 0);
      const b = ZenAdminQuery(offset: 10);
      expect(a, isNot(equals(b)));
    });

    test('inequality for different limit', () {
      const a = ZenAdminQuery(limit: 20);
      const b = ZenAdminQuery(limit: 50);
      expect(a, isNot(equals(b)));
    });

    test('toString contains offset and limit', () {
      const query = ZenAdminQuery(offset: 5, limit: 10);
      final str = query.toString();
      expect(str, contains('offset: 5'));
      expect(str, contains('limit: 10'));
    });

    test('is not equal to non-ZenAdminQuery', () {
      const query = ZenAdminQuery();
      expect(query, isNot(equals('not a query')));
    });
  });
}
