import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('Role.create', () {
    test('returns error for name too short', () {
      final result = Role.create('A');
      expect(result.isFailure, isTrue);
    });
    test('returns error for name too long', () {
      final result = Role.create('A' * 33);
      expect(result.isFailure, isTrue);
    });
    test('returns error for invalid characters', () {
      final result = Role.create('admin!');
      expect(result.isFailure, isTrue);
    });
    test('returns ok for valid name', () {
      final result = Role.create('ADMIN');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.name, 'ADMIN');
    });
  });
}
