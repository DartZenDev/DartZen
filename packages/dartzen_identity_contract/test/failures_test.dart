import 'package:dartzen_identity_contract/dartzen_identity_contract.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityContractFailure', () {
    test('IdentityFailure has correct codes', () {
      expect(IdentityFailure.notFound('id').code, 'IDENTITY_NOT_FOUND');
      expect(
        IdentityFailure.alreadyExists('id').code,
        'IDENTITY_ALREADY_EXISTS',
      );
      expect(IdentityFailure.deactivated('id').code, 'IDENTITY_DEACTIVATED');
    });

    test('AuthorityFailure has correct codes', () {
      expect(
        AuthorityFailure.permissionDenied('r', 'a').code,
        'PERMISSION_DENIED',
      );
      expect(AuthorityFailure.roleNotAssigned('r').code, 'ROLE_NOT_ASSIGNED');
    });

    test('ValidationFailure has correct codes', () {
      expect(ValidationFailure.invalidFormat('f', 'r').code, 'INVALID_FORMAT');
      expect(ValidationFailure.missingField('f').code, 'MISSING_FIELD');
    });
  });
}
