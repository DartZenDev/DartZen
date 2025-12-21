// ignore_for_file: avoid_print

import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

void main() {
  print('--- DartZen Identity Domain Example ---\n');

  // 1. Create an IdentityId
  final idResult = IdentityId.create('user_001');
  if (idResult.isFailure) {
    print('Failed to create IdentityId: ${idResult.errorOrNull?.message}');
    return;
  }
  final identityId = idResult.dataOrNull!;
  print('Step 1: Created IdentityId: $identityId');

  // 2. Create a pending Identity
  const adminRole = Role('ADMIN');
  const editCapability = Capability('can_edit_content');

  var identity = Identity.createPending(
    id: identityId,
    authority: Authority(roles: {adminRole}, capabilities: {editCapability}),
  );
  print('Step 2: Created pending identity with ADMIN role.');

  // 3. Try to perform an action (should fail because pending)
  print('\nStep 3: Checking permissions while pending...');
  final canEditResult = identity.can(editCapability);
  canEditResult.fold(
    (can) => print('Can edit: $can'),
    (error) => print('Expected failure: ${error.message}'),
  );

  // 4. Activate the identity
  final activateResult = identity.lifecycle.activate();
  if (activateResult.isSuccess) {
    identity = identity.withLifecycle(activateResult.dataOrNull!);
    print('\nStep 4: Identity activated.');
  }

  // 5. Check permissions again (should succeed)
  print('Step 5: Checking permissions while active...');
  identity
      .can(editCapability)
      .fold(
        (can) => print('Can edit: $can'),
        (error) => print('Unexpected failure: ${error.message}'),
      );

  // 6. Revoke the identity
  final revokeResult = identity.lifecycle.revoke('Security policy violation');
  if (revokeResult.isSuccess) {
    identity = identity.withLifecycle(revokeResult.dataOrNull!);
    print('\nStep 6: Identity revoked. Reason: ${identity.lifecycle.reason}');
  }

  // 7. Check permissions after revoked (should fail)
  print('Step 7: Checking permissions after revocation...');
  identity
      .can(editCapability)
      .fold(
        (can) => print('Can edit: $can'),
        (error) => print('Expected failure: ${error.message}'),
      );
}
