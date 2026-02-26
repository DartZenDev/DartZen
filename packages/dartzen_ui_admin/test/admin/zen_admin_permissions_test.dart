import 'package:dartzen_ui_admin/src/admin/zen_admin_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZenAdminPermissions', () {
    test('defaults all permissions to false', () {
      const permissions = ZenAdminPermissions();
      expect(permissions.canRead, isFalse);
      expect(permissions.canWrite, isFalse);
      expect(permissions.canDelete, isFalse);
    });

    test('accepts explicit values', () {
      const permissions = ZenAdminPermissions(
        canRead: true,
        canWrite: true,
        canDelete: true,
      );
      expect(permissions.canRead, isTrue);
      expect(permissions.canWrite, isTrue);
      expect(permissions.canDelete, isTrue);
    });

    test('copyWith replaces only specified fields', () {
      const original = ZenAdminPermissions(canRead: true);
      final copy = original.copyWith(canWrite: true);

      expect(copy.canRead, isTrue);
      expect(copy.canWrite, isTrue);
      expect(copy.canDelete, isFalse);
    });

    test('copyWith with no arguments returns equal instance', () {
      const original = ZenAdminPermissions(canRead: true, canDelete: true);
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('equality holds for same values', () {
      const a = ZenAdminPermissions(canRead: true, canWrite: false);
      const b = ZenAdminPermissions(canRead: true, canWrite: false);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different values', () {
      const a = ZenAdminPermissions(canRead: true);
      const b = ZenAdminPermissions(canWrite: true);
      expect(a, isNot(equals(b)));
    });

    test('toString contains all fields', () {
      const permissions = ZenAdminPermissions(
        canRead: true,
        canWrite: false,
        canDelete: true,
      );
      final str = permissions.toString();
      expect(str, contains('canRead: true'));
      expect(str, contains('canWrite: false'));
      expect(str, contains('canDelete: true'));
    });

    test('is not equal to non-ZenAdminPermissions', () {
      const permissions = ZenAdminPermissions();
      expect(permissions, isNot(equals('not a permission')));
    });

    test('identical instances are equal', () {
      const permissions = ZenAdminPermissions(canRead: true);
      expect(identical(permissions, permissions), isTrue);
      expect(permissions, equals(permissions));
    });
  });
}
