// ignore_for_file: avoid_print

import 'package:dartzen_identity/dartzen_identity.dart';

void main() async {
  print('=== DartZen Identity Example ===');

  // 1. Create a new identity (Value Objects ensure validity)
  final identityIdResult = IdentityId.create('user_01HMR8...');
  if (identityIdResult.isFailure) {
    print(
      'Failed to create identity ID: ${identityIdResult.errorOrNull?.message}',
    );
    return;
  }

  final id = identityIdResult.dataOrNull!;
  final identity = Identity.createPending(
    id: id,
    authority: Authority(roles: {Role.user}),
  );

  print('Created Identity: ${identity.id}');
  print('Initial State: ${identity.lifecycle.state}');

  // 2. Simulate external verification facts (Passive object)
  const facts = IdentityVerificationFacts(emailVerified: true);

  // 3. Domain Rule: Activate from facts
  final activatedResult = Identity.fromFacts(
    id: identity.id,
    authority: identity.authority,
    facts: facts,
    createdAt: identity.createdAt,
  );

  activatedResult.fold((activatedIdentity) {
    print('Activated State: ${activatedIdentity.lifecycle.state}');

    // 4. Persistence Mapping (Pure)
    final firestoreData = IdentityMapper.toFirestore(activatedIdentity);
    print('Firestore Representation: $firestoreData');

    // 5. Serialization for Transport (Contract)
    final contract = IdentityContract.fromDomain(activatedIdentity);
    print('JSON for Client: ${contract.toJson()}');
  }, (error) => print('Activation failed: ${error.message}'));

  // 6. Capability Check
  final canEdit = identity.can(const Capability.reconstruct('edit_profile'));
  canEdit.fold(
    (allowed) => print('Allowed to edit: $allowed'),
    (error) => print('Check failed: ${error.message} (Identity is pending)'),
  );
}
