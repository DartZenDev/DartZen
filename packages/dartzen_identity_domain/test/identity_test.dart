import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Identity', () {
    late IdentityId id;
    late Capability editCap;

    setUp(() {
      id = IdentityId.create('user_1').dataOrNull!;
      editCap = const Capability('can_edit');
    });

    test('new identity should be pending', () {
      final identity = Identity.createPending(id: id);
      expect(identity.lifecycle.state, IdentityState.pending);
    });

    test('can() should fail if pending', () {
      final identity = Identity.createPending(id: id);
      final result = identity.can(editCap);
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('Identity is not active'));
    });

    test('can() should succeed if active and has capability', () {
      var identity = Identity.createPending(
        id: id,
        authority: Authority(capabilities: {editCap}),
      );
      identity = identity.withLifecycle(
        identity.lifecycle.activate().dataOrNull!,
      );

      final result = identity.can(editCap);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isTrue);
    });

    test('can() should return false if active but lacks capability', () {
      var identity = Identity.createPending(id: id);
      identity = identity.withLifecycle(
        identity.lifecycle.activate().dataOrNull!,
      );

      final result = identity.can(editCap);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isFalse);
    });

    test('should support state transitions via withLifecycle', () {
      final identity = Identity.createPending(id: id);
      final activeLifecycle = identity.lifecycle.activate().dataOrNull!;
      final activeIdentity = identity.withLifecycle(activeLifecycle);

      expect(activeIdentity.lifecycle.state, IdentityState.active);
      expect(activeIdentity.id, equals(id));
    });

    test('should support authority updates via withAuthority', () {
      final identity = Identity.createPending(id: id);
      final newAuthority = Authority(roles: {const Role('ADMIN')});
      final updatedIdentity = identity.withAuthority(newAuthority);

      expect(updatedIdentity.authority.hasRole(const Role('ADMIN')), isTrue);
    });
  });
}
