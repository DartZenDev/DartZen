import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/dartzen_infrastructure_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('FirestoreIdentityCleanup', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityCleanup cleanup;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      cleanup = FirestoreIdentityCleanup(
        firestore: firestore,
        messages: createTestMessages(),
      );
    });

    test(
      'cleanupExpiredIdentities removes pending identities before cutoff',
      () async {
        // Create test identities
        final oldTimestamp = ZenTimestamp.fromMilliseconds(
          DateTime(2020).millisecondsSinceEpoch,
        );

        final oldId = IdentityId.create('old-user').dataOrNull!;
        final newId = IdentityId.create('new-user').dataOrNull!;

        final oldIdentity = Identity(
          id: oldId,
          lifecycle: IdentityLifecycle.initial(),
          authority: const Authority(),
          createdAt: oldTimestamp,
        );

        final newIdentity = Identity(
          id: newId,
          lifecycle: IdentityLifecycle.initial(),
          authority: const Authority(),
          createdAt: ZenTimestamp.now(),
        );

        final repository = FirestoreIdentityRepository(
          firestore: firestore,
          messages: createTestMessages(),
        );
        await repository.save(oldIdentity);
        await repository.save(newIdentity);

        // Run cleanup with cutoff between old and new
        final cutoff = ZenTimestamp.fromMilliseconds(
          DateTime(2021).millisecondsSinceEpoch,
        );
        final result = await cleanup.cleanupExpiredIdentities(cutoff);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 1); // Only old identity should be removed

        // Verify old is gone, new remains
        final oldResult = await repository.get(oldId);
        expect(oldResult.isFailure, isTrue);

        final newResult = await repository.get(newId);
        expect(newResult.isSuccess, isTrue);
      },
    );

    test(
      'cleanupExpiredIdentities does not remove active identities',
      () async {
        final oldTimestamp = ZenTimestamp.fromMilliseconds(
          DateTime(2020).millisecondsSinceEpoch,
        );

        final activeId = IdentityId.create('active-user').dataOrNull!;
        final activatedLifecycle = IdentityLifecycle.initial().activate();

        final activeIdentity = Identity(
          id: activeId,
          lifecycle: activatedLifecycle.dataOrNull!,
          authority: const Authority(),
          createdAt: oldTimestamp,
        );

        final repository = FirestoreIdentityRepository(
          firestore: firestore,
          messages: createTestMessages(),
        );
        await repository.save(activeIdentity);

        // Run cleanup - active identity should not be removed
        final cutoff = ZenTimestamp.now();
        final result = await cleanup.cleanupExpiredIdentities(cutoff);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 0); // No identities removed

        // Verify active identity still exists
        final activeResult = await repository.get(activeId);
        expect(activeResult.isSuccess, isTrue);
      },
    );

    test(
      'cleanupExpiredIdentities returns zero when no identities match',
      () async {
        final cutoff = ZenTimestamp.fromMilliseconds(
          DateTime(2020).millisecondsSinceEpoch,
        );

        final result = await cleanup.cleanupExpiredIdentities(cutoff);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 0);
      },
    );
  });
}
