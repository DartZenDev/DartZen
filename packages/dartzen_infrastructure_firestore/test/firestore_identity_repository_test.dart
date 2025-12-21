import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/dartzen_infrastructure_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreIdentityRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreIdentityRepository(firestore: firestore);
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
