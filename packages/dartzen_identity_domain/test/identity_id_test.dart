import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityId', () {
    test('should create valid IdentityId', () {
      final result = IdentityId.create('user_123');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.value, 'user_123');
    });

    test('should fail with empty value', () {
      final result = IdentityId.create('');
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('cannot be empty'));
    });

    test('should fail with blank value', () {
      final result = IdentityId.create('   ');
      expect(result.isFailure, isTrue);
    });

    test('should support equality', () {
      final id1 = IdentityId.create('id1').dataOrNull!;
      final id1Duplicate = IdentityId.create('id1').dataOrNull!;
      final id2 = IdentityId.create('id2').dataOrNull!;

      expect(id1, equals(id1Duplicate));
      expect(id1, isNot(equals(id2)));
      expect(id1.hashCode, equals(id1Duplicate.hashCode));
    });
  });
}
