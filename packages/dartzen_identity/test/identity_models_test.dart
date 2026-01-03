import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

T ok<T>(ZenResult<T> result) => (result as ZenSuccess<T>).data;
Object err<T>(ZenResult<T> result) => (result as ZenFailure<T>).error;

void main() {
  group('IdentityId', () {
    test('create returns ok for valid value', () {
      final result = IdentityId.create('user_1');
      expect(result.isSuccess, isTrue);
      expect(ok<IdentityId>(result), isA<IdentityId>());
      expect(ok<IdentityId>(result).value, 'user_1');
    });
    test('create returns error for empty value', () {
      final result = IdentityId.create('');
      expect(result.isFailure, isTrue);
      expect(err<IdentityId>(result), isA<ZenValidationError>());
    });
    test('equality and hashCode', () {
      final a = ok<IdentityId>(IdentityId.create('foo'));
      final b = ok<IdentityId>(IdentityId.create('foo'));
      final c = ok<IdentityId>(IdentityId.create('bar'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('Role', () {
    test('create returns ok for valid name', () {
      final result = Role.create('ADMIN');
      expect(result.isSuccess, isTrue);
      expect(ok<Role>(result), isA<Role>());
      expect(ok<Role>(result).name, 'ADMIN');
    });
    test('create returns error for invalid name', () {
      expect(Role.create('ab').isFailure, isTrue);
      expect(Role.create('admin').isFailure, isTrue);
      expect(Role.create('A!@#').isFailure, isTrue);
    });
    test('predefined roles', () {
      expect(Role.admin.name, 'ADMIN');
      expect(Role.user.name, 'USER');
    });
    test('equality and hashCode', () {
      final a = ok<Role>(Role.create('ADMIN'));
      final b = ok<Role>(Role.create('ADMIN'));
      final c = ok<Role>(Role.create('USER'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('Capability', () {
    test('create returns ok for valid id', () {
      final result = Capability.create('edit_profile');
      expect(result.isSuccess, isTrue);
      expect(ok<Capability>(result), isA<Capability>());
      expect(ok<Capability>(result).id, 'edit_profile');
    });
    test('create returns error for invalid id', () {
      expect(Capability.create('AB').isFailure, isTrue);
      expect(Capability.create('edit-Profile').isFailure, isTrue);
    });
    test('equality and hashCode', () {
      final a = ok<Capability>(Capability.create('foo'));
      final b = ok<Capability>(Capability.create('foo'));
      final c = ok<Capability>(Capability.create('bar'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('Authority', () {
    test('hasRole and hasCapability', () {
      final Role role = ok<Role>(Role.create('ADMIN'));
      final Capability cap = ok<Capability>(Capability.create('edit'));
      final auth = Authority(roles: {role}, capabilities: {cap});
      expect(auth.hasRole(role), isTrue);
      expect(auth.hasCapability(cap), isTrue);
      final Role userRole = ok<Role>(Role.create('USER'));
      final Capability viewCap = ok<Capability>(Capability.create('view'));
      expect(auth.hasRole(userRole), isFalse);
      expect(auth.hasCapability(viewCap), isFalse);
    });
    test('equality and hashCode', () {
      final Role r = ok<Role>(Role.create('ADMIN'));
      final Capability c = ok<Capability>(Capability.create('edit'));
      final a1 = Authority(roles: {r}, capabilities: {c});
      final a2 = Authority(roles: {r}, capabilities: {c});
      expect(a1, a2);
      expect(a1.hashCode, a2.hashCode);
    });
  });

  group('IdentityLifecycle', () {
    test('initial is pending', () {
      final l = IdentityLifecycle.initial();
      expect(l.state, IdentityState.pending);
      expect(l.reason, isNull);
    });
    test('activate transitions to active', () {
      final l = IdentityLifecycle.initial();
      final result = l.activate();
      expect(result.isSuccess, isTrue);
      expect(ok<IdentityLifecycle>(result).state, IdentityState.active);
    });
    test('revoke requires reason', () {
      final l = IdentityLifecycle.initial();
      final result = l.revoke('');
      expect(result.isFailure, isTrue);
      expect(err<IdentityLifecycle>(result), isA<ZenValidationError>());
    });
    test('disable transitions to disabled', () {
      final l = IdentityLifecycle.initial();
      final result = l.disable('reason');
      expect(result.isSuccess, isTrue);
      expect(ok<IdentityLifecycle>(result).state, IdentityState.disabled);
    });
    test('equality and hashCode', () {
      final l1 = IdentityLifecycle.initial();
      final l2 = IdentityLifecycle.initial();
      expect(l1, l2);
      expect(l1.hashCode, l2.hashCode);
    });
  });

  group('IdentityVerificationFacts', () {
    test('equality and hashCode', () {
      const a = IdentityVerificationFacts(emailVerified: true);
      const b = IdentityVerificationFacts(emailVerified: true);
      const c = IdentityVerificationFacts(emailVerified: false);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
