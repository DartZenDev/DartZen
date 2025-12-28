import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('Identity', () {
    final id = IdentityId.create('user_123').dataOrNull!;

    test('createPending should create an identity in pending state', () {
      final identity = Identity.createPending(id: id);
      expect(identity.id, id);
      expect(identity.lifecycle.state, IdentityState.pending);
    });

    test('fromFacts should activate identity if email is verified', () {
      const facts = IdentityVerificationFacts(emailVerified: true);
      final result = Identity.fromFacts(
        id: id,
        authority: const Authority(),
        facts: facts,
        createdAt: ZenTimestamp.now(),
      );

      final identity = (result as ZenSuccess<Identity>).data;
      expect(identity.lifecycle.state, IdentityState.active);
    });

    test('can should fail if identity is not active', () {
      final identity = Identity.createPending(id: id);
      const capability = Capability.reconstruct('edit');

      final result = identity.can(capability);
      expect(result.isFailure, isTrue);
    });

    test('can should succeed if identity has capability', () {
      const capability = Capability.reconstruct('edit');
      final identity = Identity(
        id: id,
        lifecycle: const IdentityLifecycle.reconstruct(IdentityState.active),
        authority: Authority(capabilities: {capability}),
        createdAt: ZenTimestamp.now(),
      );

      final result = identity.can(capability);
      expect((result as ZenSuccess<bool>).data, isTrue);
    });
  });

  group('IdentityMapper', () {
    test('round-trip should be consistent', () {
      final id = IdentityId.create('user_123').dataOrNull!;
      final identity = Identity(
        id: id,
        lifecycle: const IdentityLifecycle.reconstruct(
          IdentityState.active,
          'Reason',
        ),
        authority: Authority(roles: {Role.admin}),
        createdAt: ZenTimestamp.now(),
      );

      final firestoreData = IdentityMapper.toFirestore(identity);
      final result = IdentityMapper.fromFirestore(id.value, firestoreData);

      final mappedIdentity = (result as ZenSuccess<Identity>).data;
      expect(mappedIdentity.id, identity.id);
      expect(mappedIdentity.lifecycle, identity.lifecycle);
      expect(mappedIdentity.authority, identity.authority);
      expect(
        mappedIdentity.createdAt.millisecondsSinceEpoch,
        identity.createdAt.millisecondsSinceEpoch,
      );
    });
  });

  group('IdentityContract', () {
    test('serialization round-trip should be consistent', () {
      final id = IdentityId.create('user_123').dataOrNull!;
      final identity = Identity(
        id: id,
        lifecycle: const IdentityLifecycle.reconstruct(IdentityState.active),
        authority: Authority(roles: {Role.user}),
        createdAt: ZenTimestamp.now(),
      );

      final contract = IdentityContract.fromDomain(identity);
      final json = contract.toJson();
      final fromJson = IdentityContract.fromJson(json);

      expect(fromJson.id, identity.id.value);
      expect(fromJson.lifecycle.state, identity.lifecycle.state.name);
      expect(fromJson.authority.roles, contains(Role.user.name));
    });
  });

  group('Validation', () {
    test('Role.create should validate name', () {
      expect(Role.create('AB').isFailure, isTrue);
      expect(Role.create('isValid').isFailure, isTrue); // Must be uppercase
      expect(Role.create('ADMIN').isSuccess, isTrue);
    });

    test('Capability.create should validate ID', () {
      expect(Capability.create('ab').isFailure, isTrue);
      expect(
        Capability.create('Is_Valid').isFailure,
        isTrue,
      ); // Must be lowercase
      expect(Capability.create('edit_profile').isSuccess, isTrue);
    });
  });

  group('IdentityMapper Edge Cases', () {
    test('fromFirestore should return error if field is missing', () {
      final result = IdentityMapper.fromFirestore('user_123', {
        'authority': {'roles': <String>[], 'capabilities': <String>[]},
        'createdAt': 123456789,
      });
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('lifecycle'));
    });
  });
}
