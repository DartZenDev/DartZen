import 'package:dartzen_ui_admin/src/admin/zen_admin_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZenAdminField', () {
    test('defaults visibleInList and editable to true, required to false', () {
      const field = ZenAdminField(name: 'email', label: 'Email');
      expect(field.visibleInList, isTrue);
      expect(field.editable, isTrue);
      expect(field.required, isFalse);
    });

    test('accepts all explicit values', () {
      const field = ZenAdminField(
        name: 'id',
        label: 'ID',
        visibleInList: true,
        editable: false,
        required: true,
      );
      expect(field.name, 'id');
      expect(field.label, 'ID');
      expect(field.visibleInList, isTrue);
      expect(field.editable, isFalse);
      expect(field.required, isTrue);
    });

    test('equality holds for same values', () {
      const a = ZenAdminField(name: 'name', label: 'Name');
      const b = ZenAdminField(name: 'name', label: 'Name');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different name', () {
      const a = ZenAdminField(name: 'name', label: 'Name');
      const b = ZenAdminField(name: 'email', label: 'Name');
      expect(a, isNot(equals(b)));
    });

    test('inequality for different label', () {
      const a = ZenAdminField(name: 'name', label: 'Name');
      const b = ZenAdminField(name: 'name', label: 'Full Name');
      expect(a, isNot(equals(b)));
    });

    test('inequality for different visibleInList', () {
      const a = ZenAdminField(name: 'x', label: 'X', visibleInList: true);
      const b = ZenAdminField(name: 'x', label: 'X', visibleInList: false);
      expect(a, isNot(equals(b)));
    });

    test('inequality for different editable', () {
      const a = ZenAdminField(name: 'x', label: 'X', editable: true);
      const b = ZenAdminField(name: 'x', label: 'X', editable: false);
      expect(a, isNot(equals(b)));
    });

    test('inequality for different required', () {
      const a = ZenAdminField(name: 'x', label: 'X', required: true);
      const b = ZenAdminField(name: 'x', label: 'X', required: false);
      expect(a, isNot(equals(b)));
    });

    test('toString contains all fields', () {
      const field = ZenAdminField(
        name: 'email',
        label: 'Email',
        visibleInList: false,
        editable: true,
        required: true,
      );
      final str = field.toString();
      expect(str, contains('name: email'));
      expect(str, contains('label: Email'));
      expect(str, contains('visibleInList: false'));
      expect(str, contains('editable: true'));
      expect(str, contains('required: true'));
    });

    test('is not equal to non-ZenAdminField', () {
      const field = ZenAdminField(name: 'x', label: 'X');
      expect(field, isNot(equals('not a field')));
    });

    test('hidden non-editable optional field', () {
      const field = ZenAdminField(
        name: 'internal',
        label: 'Internal',
        visibleInList: false,
        editable: false,
        required: false,
      );
      expect(field.visibleInList, isFalse);
      expect(field.editable, isFalse);
      expect(field.required, isFalse);
    });
  });
}
