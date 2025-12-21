import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityMapper', () {
    const mapper = IdentityMapper();
    final now = ZenTimestamp.now();
    final id = IdentityId.create('zen_123').fold((s) => s, (e) => throw e);

    test('maps verified identity correctly', () {
      const external = InfrastructureExternalIdentity(
        subject: 'sub_123',
        claims: {
          'email_verified': true,
          'roles': ['ADMIN'],
          'capabilities': ['can_delete'],
        },
      );

      final result = mapper.mapToDomain(
        id: id,
        external: external,
        createdAt: now,
      );

      expect(result.isSuccess, isTrue);
      final identity = result.dataOrNull!;
      expect(identity.id, equals(id));
      expect(identity.lifecycle.state, equals(IdentityState.active));
      expect(identity.authority.hasRole(const Role('ADMIN')), isTrue);
      expect(identity.can(const Capability('can_delete')).dataOrNull!, isTrue);
    });

    test('maps unverified identity as pending', () {
      const external = InfrastructureExternalIdentity(
        subject: 'sub_123',
        claims: {'email_verified': false},
      );

      final result = mapper.mapToDomain(
        id: id,
        external: external,
        createdAt: now,
      );

      expect(result.isSuccess, isTrue);
      final identity = result.dataOrNull!;
      expect(identity.lifecycle.state, equals(IdentityState.pending));
    });

    test('handles missing claims gracefully', () {
      const external = InfrastructureExternalIdentity(
        subject: 'sub_123',
        claims: {},
      );

      final result = mapper.mapToDomain(
        id: id,
        external: external,
        createdAt: now,
      );

      expect(result.isSuccess, isTrue);
      final identity = result.dataOrNull!;
      expect(identity.authority.roles, isEmpty);
      expect(identity.lifecycle.state, equals(IdentityState.pending));
    });
  });
}
