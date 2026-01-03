import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('AuthorityContract', () {
    test('toDomain with invalid role/capability', () {
      const contract = AuthorityContract(
        roles: ['INVALID!'],
        capabilities: ['invalid-cap'],
      );
      final authority = contract.toDomain();
      // Should reconstruct as-is, even if invalid, since reconstruct bypasses validation
      expect(authority.roles.first.name, 'INVALID!');
      expect(authority.capabilities.first.id, 'invalid-cap');
    });
  });
}
