// Example: Using dartzen_infrastructure_firestore
//
// This demonstrates how to wire the Firestore adapter to your domain services.
//
// NOTE: This is a documentation example only. Real applications would initialize
// Firebase and connect to an actual Firestore instance.

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/dartzen_infrastructure_firestore.dart';
import 'package:dartzen_infrastructure_firestore/src/l10n/firestore_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

void main() async {
  // Initialize Firestore (actual initialization omitted for example clarity)
  // In a real app, you would call Firebase.initializeApp() first
  final firestore = FirebaseFirestore.instance;

  // Set up localization
  final localization = ZenLocalizationService(
    config: const ZenLocalizationConfig(isProduction: true),
  );
  await localization.loadGlobalMessages('en');
  final messages = FirestoreMessages(localization, 'en');

  // Create the repository
  final repository = FirestoreIdentityRepository(
    firestore: firestore,
    messages: messages,
  );

  // Example: Create and save an identity
  final idResult = IdentityId.create('user-123');
  if (idResult.isFailure) {
    print('Failed to create ID: ${idResult.errorOrNull}');
    return;
  }

  final identity = Identity.createPending(
    id: idResult.dataOrNull!,
    authority: Authority(
      roles: {const Role('member')},
      capabilities: {const Capability('read_documents')},
    ),
  );

  // Save to Firestore
  final saveResult = await repository.save(identity);
  saveResult.fold(
    (_) => print('Identity saved successfully'),
    (error) => print('Failed to save: $error'),
  );

  // Example: Load an identity
  final loadResult = await repository.get(idResult.dataOrNull!);
  loadResult.fold((loadedIdentity) {
    print('Loaded identity: ${loadedIdentity.id}');
    print('State: ${loadedIdentity.lifecycle.state}');
    print('Roles: ${loadedIdentity.authority.roles.map((r) => r.name)}');
  }, (error) => print('Failed to load: $error'));

  // Example: Activate an identity
  final activationResult = identity.lifecycle.activate();
  if (activationResult.isSuccess) {
    final activatedIdentity = identity.withLifecycle(
      activationResult.dataOrNull!,
    );
    await repository.save(activatedIdentity);
    print('Identity activated');
  }

  // Example: Cleanup expired identities
  final cleanup = FirestoreIdentityCleanup(
    firestore: firestore,
    messages: messages,
  );

  final cutoffTimestamp = ZenTimestamp.fromMilliseconds(
    DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
  );

  final cleanupResult = await cleanup.cleanupExpiredIdentities(cutoffTimestamp);
  cleanupResult.fold(
    (count) => print('Cleaned up $count expired identities'),
    (error) => print('Cleanup failed: $error'),
  );

  // Example: Using as an IdentityProvider
  final provider = repository as IdentityProvider;

  final externalResult = await provider.getIdentity('user-123');
  externalResult.fold((externalIdentity) {
    print('External identity subject: ${externalIdentity.subject}');
    print('Claims: ${externalIdentity.claims}');
  }, (error) => print('Failed to get external identity: $error'));

  // Example: Error handling
  final missingResult = await repository.get(
    IdentityId.create('non-existent').dataOrNull!,
  );

  if (missingResult.isFailure) {
    final error = missingResult.errorOrNull!;
    if (error is ZenNotFoundError) {
      print('Identity not found (expected)');
    } else {
      print('Unexpected error: $error');
    }
  }
}
