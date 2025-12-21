import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Authority', () {
    test('should evaluate capabilities correctly', () {
      const cap1 = Capability('cap1');
      const cap2 = Capability('cap2');
      final authority = Authority(capabilities: {cap1});

      expect(authority.hasCapability(cap1), isTrue);
      expect(authority.hasCapability(cap2), isFalse);
    });

    test('should evaluate roles correctly', () {
      const role1 = Role('ADMIN');
      const role2 = Role('USER');
      final authority = Authority(roles: {role1});

      expect(authority.hasRole(role1), isTrue);
      expect(authority.hasRole(role2), isFalse);
    });

    test('should support equality', () {
      const role = Role('R1');
      const cap = Capability('C1');
      final auth1 = Authority(roles: {role}, capabilities: {cap});
      final auth1Duplicate = Authority(roles: {role}, capabilities: {cap});
      final auth2 = Authority(roles: {role});

      expect(auth1, equals(auth1Duplicate));
      expect(auth1, isNot(equals(auth2)));
    });
  });
}
