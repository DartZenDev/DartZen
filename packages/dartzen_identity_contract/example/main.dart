import 'dart:convert';

import 'package:dartzen_identity_contract/dartzen_identity_contract.dart';

// ignore_for_file: avoid_print

void main() {
  print('--- DartZen Identity Contract Example ---\n');

  // 1. Create Identity Structures
  const userId = IdentityId('user-007');

  const readDocs = Capability(resource: 'docs', action: 'read');
  const editDocs = Capability(resource: 'docs', action: 'edit');

  const editorRole = Role(
    id: 'editor',
    name: 'Document Editor',
    capabilities: [readDocs, editDocs],
  );

  const authority = Authority(
    identityId: userId,
    roles: [editorRole],
    effectiveCapabilities: [readDocs, editDocs],
  );

  print('Created Authority: $authority');
  print('Has edit permission? ${authority.hasCapability('docs', 'edit')}');
  print('Has delete permission? ${authority.hasCapability('docs', 'delete')}');

  // 2. Serialization
  print('\n--- Serialization ---');
  final jsonMap = authority.toJson();
  final jsonString = jsonEncode(jsonMap);
  print('Serialized JSON: $jsonString');

  // 3. Deserialization
  final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
  final restoredAuthority = Authority.fromJson(decodedMap);
  print('Restored Authority: $restoredAuthority');

  assert(authority.identityId == restoredAuthority.identityId);
  print('Round-trip check passed ✅');

  // 4. Lifecycle States
  print('\n--- Lifecycle ---');
  const state = IdentityLifecycleState.active;
  print('Current State: $state');
  print('Serialized State: ${state.toJson()}');
  print('Restored State: ${IdentityLifecycleState.fromJson('active')}');
  print(
    'Unknown State Fallback: ${IdentityLifecycleState.fromJson('alien_state')}',
  ); // Should be deactivated

  // 5. Failures
  print('\n--- Failures ---');
  final failure = IdentityFailure.notFound('user-999');
  print('Failure: ${failure.message}');
  print('Error Code: ${failure.code}');
}
