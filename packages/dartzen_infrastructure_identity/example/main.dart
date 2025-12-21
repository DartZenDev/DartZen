import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';

void main() {
  // 1. Initialize the mapper
  const mapper = IdentityMapper();

  // 2. Simulate an external identity from an IdP (e.g., Firebase, Auth0)
  const external = InfrastructureExternalIdentity(
    subject: 'auth0|12345',
    claims: {
      'name': 'John Doe',
      'email': 'john@example.com',
      'email_verified': true,
      'roles': ['MEMBER', 'EDITOR'],
      'capabilities': ['can_edit_own_posts'],
    },
  );

  // 3. Map to domain Identity
  final result = mapper.mapToDomain(
    id: IdentityId.create('zen_user_001').fold((s) => s, (e) => throw e),
    external: external,
    createdAt: ZenTimestamp.now(),
  );

  result.fold(
    (identity) {
      // ignore: avoid_print
      print('--- Identity Mapped Successfully ---');
      // ignore: avoid_print
      print('ID: ${identity.id.value}');
      // ignore: avoid_print
      print('State: ${identity.lifecycle.state.name}');
      // ignore: avoid_print
      print('Roles: ${identity.authority.roles.map((r) => r.name).join(', ')}');

      // Check capability
      final canEdit = identity.can(const Capability('can_edit_own_posts'));
      // ignore: avoid_print
      print('Can edit own posts: ${canEdit.dataOrNull ?? false}');
    },
    (error) {
      // ignore: avoid_print
      print('Error mapping identity: ${error.message}');
    },
  );

  // 4. Using adapters
  final hooks = InfrastructureIdentityHooks();
  // ignore: avoid_print
  print('\n--- Identity Hooks ---');
  // ignore: avoid_print
  print('Hooks instance created: ${hooks.runtimeType}');
}
