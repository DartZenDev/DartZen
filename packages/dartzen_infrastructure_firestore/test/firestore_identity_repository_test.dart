import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/dartzen_infrastructure_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('FirestoreIdentityRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreIdentityRepository(
        firestore: firestore,
        messages: createTestMessages(),
      );
    });

    final testId = IdentityId.create('user-123').dataOrNull!;
    final testIdentity = Identity.createPending(id: testId);

    test('save persists identity to Firestore', () async {
      final result = await repository.save(testIdentity);

      expect(result.isSuccess, isTrue);

      final doc = await firestore
          .collection('identities')
          .doc('user-123')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['lifecycle_state'], 'pending');
    });

    test('get retrieves persisted identity', () async {
      await repository.save(testIdentity);

      final result = await repository.get(testId);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.id, testId);
    });

    test('get returns error for non-existent identity', () async {
      final result = await repository.get(
        IdentityId.create('ghost').dataOrNull!,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenNotFoundError>());
    });

    test('delete removes identity from Firestore', () async {
      await repository.save(testIdentity);

      final deleteResult = await repository.delete(testId);
      expect(deleteResult.isSuccess, isTrue);

      final doc = await firestore
          .collection('identities')
          .doc('user-123')
          .get();
      expect(doc.exists, isFalse);
    });

    test('save and retrieve identity with revoked lifecycle', () async {
      final revokedIdentity = testIdentity.lifecycle.revoke('TOS violation');
      expect(revokedIdentity.isSuccess, isTrue);

      final identityWithRevoked = Identity(
        id: testId,
        lifecycle: revokedIdentity.dataOrNull!,
        authority: testIdentity.authority,
        createdAt: testIdentity.createdAt,
      );

      final saveResult = await repository.save(identityWithRevoked);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await repository.get(testId);
      expect(getResult.isSuccess, isTrue);
      expect(getResult.dataOrNull!.lifecycle.state, IdentityState.revoked);
      expect(getResult.dataOrNull!.lifecycle.reason, 'TOS violation');
    });

    test('save and retrieve identity with disabled lifecycle', () async {
      final disabledIdentity = testIdentity.lifecycle.disable(
        'Account suspended',
      );
      expect(disabledIdentity.isSuccess, isTrue);

      final identityWithDisabled = Identity(
        id: testId,
        lifecycle: disabledIdentity.dataOrNull!,
        authority: testIdentity.authority,
        createdAt: testIdentity.createdAt,
      );

      final saveResult = await repository.save(identityWithDisabled);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await repository.get(testId);
      expect(getResult.isSuccess, isTrue);
      expect(getResult.dataOrNull!.lifecycle.state, IdentityState.disabled);
      expect(getResult.dataOrNull!.lifecycle.reason, 'Account suspended');
    });

    test('save and retrieve identity with all fields populated', () async {
      final fullAuthority = Authority(
        roles: {const Role('admin'), const Role('moderator')},
        capabilities: {
          const Capability('read'),
          const Capability('write'),
          const Capability('delete'),
        },
      );

      final activeLifecycle = testIdentity.lifecycle.activate();
      expect(activeLifecycle.isSuccess, isTrue);

      final fullIdentity = Identity(
        id: testId,
        lifecycle: activeLifecycle.dataOrNull!,
        authority: fullAuthority,
        createdAt: testIdentity.createdAt,
      );

      final saveResult = await repository.save(fullIdentity);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await repository.get(testId);
      expect(getResult.isSuccess, isTrue);

      final retrieved = getResult.dataOrNull!;
      expect(retrieved.id, testId);
      expect(retrieved.lifecycle.state, IdentityState.active);
      expect(retrieved.authority.roles.length, 2);
      expect(retrieved.authority.capabilities.length, 3);
    });

    test('save is idempotent (multiple saves of same identity)', () async {
      // Save same identity multiple times
      final result1 = await repository.save(testIdentity);
      expect(result1.isSuccess, isTrue);

      final result2 = await repository.save(testIdentity);
      expect(result2.isSuccess, isTrue);

      final result3 = await repository.save(testIdentity);
      expect(result3.isSuccess, isTrue);

      // Verify only one document exists
      final doc = await firestore
          .collection('identities')
          .doc('user-123')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['lifecycle_state'], 'pending');
    });

    group('IdentityProvider Implementation', () {
      test('getIdentity retrieves external identity from storage', () async {
        // Setup: Save a document first (simulating it exists)
        // Note: getIdentity assumes 1:1 map, so we use 'user-123' as subject
        await repository.save(testIdentity);

        final result = await repository.getIdentity('user-123');

        expect(result.isSuccess, isTrue);
        final ext = result.dataOrNull!;
        expect(ext.subject, 'user-123');
        expect(ext.claims['lifecycle_state'], 'pending');
      });

      test('resolveId maps external subject 1:1 to IdentityId', () async {
        final ext = _FakeExternalIdentity('user-abc');
        final result = await repository.resolveId(ext);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!, IdentityId.create('user-abc').dataOrNull!);
      });
    });
  });
}

class _FakeExternalIdentity implements ExternalIdentity {
  @override
  final String subject;
  @override
  final Map<String, dynamic> claims = {};

  _FakeExternalIdentity(this.subject);
}
