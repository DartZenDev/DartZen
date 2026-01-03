import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('Role.create', () {
    test('returns error for name too short', () {
      final result = Role.create('AB');
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull.toString(), contains('between 3 and 32'));
    });
    test('returns error for name too long', () {
      final result = Role.create('A' * 33);
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull.toString(), contains('between 3 and 32'));
    });
    test('returns error for invalid characters', () {
      final result = Role.create('ADMIN!');
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull.toString(), contains('uppercase alphanumeric'));
    });
    test('returns ok for valid name', () {
      final result = Role.create('ADMIN');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<Role>());
      expect(result.dataOrNull!.name, 'ADMIN');
    });
  });
}
