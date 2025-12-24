import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/dartzen_infrastructure_firestore.dart';
import 'package:dartzen_infrastructure_firestore/src/models/firestore_external_identity.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('FirestoreIdentityCleanup - Edge Cases', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityCleanup cleanup;
    late FirestoreIdentityRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      cleanup = FirestoreIdentityCleanup(
        firestore: firestore,
        messages: createTestMessages(),
      );
      repository = FirestoreIdentityRepository(
        firestore: firestore,
        messages: createTestMessages(),
      );
    });

    test('handles empty database gracefully', () async {
      final cutoff = ZenTimestamp.now();
      final result = await cleanup.cleanupExpiredIdentities(cutoff);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 0);
    });

    test('handles large dataset with batching', () async {
      // Create 600 expired identities to test batch handling (>500 limit)
      final oldTimestamp = ZenTimestamp.fromMilliseconds(
        DateTime(2020).millisecondsSinceEpoch,
      );

      for (var i = 0; i < 600; i++) {
        final id = IdentityId.create('user-$i').dataOrNull!;
        final identity = Identity(
          id: id,
          lifecycle: IdentityLifecycle.initial(),
          authority: const Authority(),
          createdAt: oldTimestamp,
        );
        await repository.save(identity);
      }

      final cutoff = ZenTimestamp.now();
      final result = await cleanup.cleanupExpiredIdentities(cutoff);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 600);

      // Verify all identities were deleted
      for (var i = 0; i < 600; i++) {
        final id = IdentityId.create('user-$i').dataOrNull!;
        final getResult = await repository.get(id);
        expect(getResult.isFailure, isTrue);
      }
    });

    test('handles timestamp at exact boundary', () async {
      final boundaryTime = ZenTimestamp.fromMilliseconds(
        DateTime(2023, 6, 15).millisecondsSinceEpoch,
      );

      // Identity exactly at boundary
      final id1 = IdentityId.create('boundary-user').dataOrNull!;
      final identity1 = Identity(
        id: id1,
        lifecycle: IdentityLifecycle.initial(),
        authority: const Authority(),
        createdAt: boundaryTime,
      );
      await repository.save(identity1);

      // Identity one millisecond before
      final beforeTime = ZenTimestamp.fromMilliseconds(
        boundaryTime.value.millisecondsSinceEpoch - 1,
      );
      final id2 = IdentityId.create('before-user').dataOrNull!;
      final identity2 = Identity(
        id: id2,
        lifecycle: IdentityLifecycle.initial(),
        authority: const Authority(),
        createdAt: beforeTime,
      );
      await repository.save(identity2);

      // Cleanup with boundary timestamp
      final result = await cleanup.cleanupExpiredIdentities(boundaryTime);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 1); // Only before-user should be deleted

      // Verify boundary user still exists
      final boundaryResult = await repository.get(id1);
      expect(boundaryResult.isSuccess, isTrue);

      // Verify before user was deleted
      final beforeResult = await repository.get(id2);
      expect(beforeResult.isFailure, isTrue);
    });

    test('handles future timestamp gracefully', () async {
      final futureTime = ZenTimestamp.fromMilliseconds(
        DateTime(2099).millisecondsSinceEpoch,
      );

      final id = IdentityId.create('current-user').dataOrNull!;
      final identity = Identity(
        id: id,
        lifecycle: IdentityLifecycle.initial(),
        authority: const Authority(),
        createdAt: ZenTimestamp.now(),
      );
      await repository.save(identity);

      final result = await cleanup.cleanupExpiredIdentities(futureTime);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 1); // Current user cleaned up

      final getResult = await repository.get(id);
      expect(getResult.isFailure, isTrue);
    });

    test('only deletes pending identities, not active ones', () async {
      final oldTimestamp = ZenTimestamp.fromMilliseconds(
        DateTime(2020).millisecondsSinceEpoch,
      );

      // Create mix of pending and active old identities
      for (var i = 0; i < 5; i++) {
        final id = IdentityId.create('pending-$i').dataOrNull!;
        final identity = Identity(
          id: id,
          lifecycle: IdentityLifecycle.initial(),
          authority: const Authority(),
          createdAt: oldTimestamp,
        );
        await repository.save(identity);
      }

      for (var i = 0; i < 5; i++) {
        final id = IdentityId.create('active-$i').dataOrNull!;
        final activatedLifecycle = IdentityLifecycle.initial().activate();
        final identity = Identity(
          id: id,
          lifecycle: activatedLifecycle.dataOrNull!,
          authority: const Authority(),
          createdAt: oldTimestamp,
        );
        await repository.save(identity);
      }

      final cutoff = ZenTimestamp.now();
      final result = await cleanup.cleanupExpiredIdentities(cutoff);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 5); // Only pending deleted

      // Verify active identities still exist
      for (var i = 0; i < 5; i++) {
        final id = IdentityId.create('active-$i').dataOrNull!;
        final getResult = await repository.get(id);
        expect(getResult.isSuccess, isTrue);
      }
    });
  });

  group('FirestoreIdentityRepository - Error Paths', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreIdentityRepository(
        firestore: firestore,
        messages: createTestMessages(),
      );
    });

    test('get handles missing document correctly', () async {
      final id = IdentityId.create('nonexistent').dataOrNull!;
      final result = await repository.get(id);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenNotFoundError>());
    });

    test('delete succeeds even if document does not exist', () async {
      final id = IdentityId.create('never-existed').dataOrNull!;
      final result = await repository.delete(id);

      // Firestore delete is idempotent - succeeds even if doc doesn't exist
      expect(result.isSuccess, isTrue);
    });

    test('save is truly idempotent - multiple saves succeed', () async {
      final id = IdentityId.create('idempotent-test').dataOrNull!;
      final identity = Identity.createPending(id: id);

      // Save multiple times
      for (var i = 0; i < 3; i++) {
        final result = await repository.save(identity);
        expect(result.isSuccess, isTrue);
      }

      // Verify only one document exists
      final getResult = await repository.get(id);
      expect(getResult.isSuccess, isTrue);
    });

    test('getIdentity returns normalized claims without Timestamps', () async {
      final id = IdentityId.create('claims-test').dataOrNull!;
      final identity = Identity.createPending(id: id);
      await repository.save(identity);

      final result = await repository.getIdentity(id.value);

      expect(result.isSuccess, isTrue);
      final externalIdentity = result.dataOrNull!;

      // Verify claims contains no Timestamp objects
      void assertNoTimestamps(dynamic value) {
        if (value is Map) {
          for (final v in value.values) {
            assertNoTimestamps(v);
          }
        } else if (value is List) {
          for (final v in value) {
            assertNoTimestamps(v);
          }
        }
        // If this fails, a Timestamp leaked through
        expect(value.runtimeType.toString().contains('Timestamp'), isFalse);
      }

      assertNoTimestamps(externalIdentity.claims);
    });

    test('resolveId returns error for invalid ID', () async {
      const external = FirestoreExternalIdentity(subject: '', claims: {});

      final result = await repository.resolveId(external);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenValidationError>());
    });

    test('resolveId succeeds for valid subject', () async {
      const external = FirestoreExternalIdentity(
        subject: 'valid-subject-123',
        claims: {},
      );

      final result = await repository.resolveId(external);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.value, 'valid-subject-123');
    });
  });
}
