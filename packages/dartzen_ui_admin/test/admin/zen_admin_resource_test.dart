import 'package:dartzen_ui_admin/src/admin/zen_admin_field.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_permissions.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const field = ZenAdminField(name: 'name', label: 'Name');
  const permissions = ZenAdminPermissions(canRead: true);

  group('ZenAdminResource', () {
    test('creates with valid arguments', () {
      final resource = ZenAdminResource<Map<String, dynamic>>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      expect(resource.resourceName, 'users');
      expect(resource.displayName, 'Users');
      expect(resource.fields, [field]);
      expect(resource.permissions, permissions);
      expect(resource.idFieldName, 'id');
    });

    test('accepts custom idFieldName', () {
      final resource = ZenAdminResource<Map<String, dynamic>>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
        idFieldName: 'userId',
      );
      expect(resource.idFieldName, 'userId');
    });

    test('fields list is unmodifiable', () {
      final resource = ZenAdminResource<Map<String, dynamic>>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      expect(
        () => resource.fields.add(
          const ZenAdminField(name: 'extra', label: 'Extra'),
        ),
        throwsUnsupportedError,
      );
    });

    test('assert fires for empty resourceName', () {
      expect(
        () => ZenAdminResource<void>(
          resourceName: '',
          displayName: 'X',
          fields: const [field],
          permissions: permissions,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert fires for empty fields', () {
      expect(
        () => ZenAdminResource<void>(
          resourceName: 'x',
          displayName: 'X',
          fields: const [],
          permissions: permissions,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality for same values', () {
      final a = ZenAdminResource<Map<String, dynamic>>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      final b = ZenAdminResource<Map<String, dynamic>>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different idFieldName', () {
      final a = ZenAdminResource<void>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      final b = ZenAdminResource<void>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
        idFieldName: 'uid',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality for different resourceName', () {
      final a = ZenAdminResource<void>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      final b = ZenAdminResource<void>(
        resourceName: 'roles',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality for different generic type', () {
      final a = ZenAdminResource<String>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      final b = ZenAdminResource<int>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      expect(a, isNot(equals(b)));
    });

    test('toString contains type and resource name', () {
      final resource = ZenAdminResource<String>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      final str = resource.toString();
      expect(str, contains('ZenAdminResource<String>'));
      expect(str, contains('resourceName: users'));
    });

    test('supports multiple fields', () {
      const field2 = ZenAdminField(name: 'email', label: 'Email');
      final resource = ZenAdminResource<void>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field, field2],
        permissions: permissions,
      );
      expect(resource.fields.length, 2);
    });

    test('is not equal to non-ZenAdminResource', () {
      final resource = ZenAdminResource<void>(
        resourceName: 'users',
        displayName: 'Users',
        fields: const [field],
        permissions: permissions,
      );
      expect(resource, isNot(equals('not a resource')));
    });
  });
}
