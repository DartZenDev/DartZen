import 'package:dartzen_identity_contract/dartzen_identity_contract.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityId', () {
    test('should be equal if values are equal', () {
      expect(const IdentityId('123'), equals(const IdentityId('123')));
    });

    test('should not allow empty values', () {
      expect(() => IdentityId(''), throwsA(isA<AssertionError>()));
    });

    test('toJson returns plain string', () {
      expect(const IdentityId('abc').toJson(), 'abc');
    });

    test('fromJson creates instance', () {
      expect(IdentityId.fromJson('abc'), const IdentityId('abc'));
    });
  });

  group('IdentityLifecycleState', () {
    test('serialization round-trip', () {
      for (final value in IdentityLifecycleState.values) {
        expect(IdentityLifecycleState.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to deactivated for unknown values', () {
      expect(
        IdentityLifecycleState.fromJson('unknown_state'),
        IdentityLifecycleState.deactivated,
      );
    });
  });

  group('AuthorityFailure', () {
    test('AuthorityFailure has correct codes', () {
      expect(
        AuthorityFailure.permissionDenied('r', 'a').code,
        'PERMISSION_DENIED',
      );
      expect(AuthorityFailure.roleNotAssigned('r').code, 'ROLE_NOT_ASSIGNED');
    });
  });

  group('ValidationFailure', () {
    test('ValidationFailure has correct codes', () {
      expect(ValidationFailure.invalidFormat('f', 'r').code, 'INVALID_FORMAT');
      expect(ValidationFailure.missingField('f').code, 'MISSING_FIELD');
    });
  });

  group('Authority & Roles', () {
    test('full serialization round-trip', () {
      const cap = Capability(resource: 'res', action: 'act');
      const role = Role(id: 'r1', name: 'Role 1', capabilities: [cap]);
      const authority = Authority(
        identityId: IdentityId('user1'),
        roles: [role],
        effectiveCapabilities: [cap],
      );

      final json = authority.toJson();
      final restored = Authority.fromJson(json);

      expect(restored.identityId, authority.identityId);
      expect(restored.roles.length, 1);
      expect(restored.roles.first.id, 'r1');
      expect(restored.effectiveCapabilities.length, 1);
      expect(restored.hasCapability('res', 'act'), isTrue);
    });
  });
}
