import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = FirestoreIdentityRepository(firestore: firestore);
    });

    test(
      'getIdentityById should return ZenNotFoundError if document missing',
      () async {
        const id = IdentityId.reconstruct('missing');
        final result = await repo.getIdentityById(id);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenNotFoundError>());
      },
    );

    test('createIdentity should store identity in Firestore', () async {
      const id = IdentityId.reconstruct('user_1');
      final identity = Identity.createPending(id: id);

      final result = await repo.createIdentity(identity);
      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('identities').doc(id.value).get();
      expect(doc.exists, isTrue);
      expect(
        doc.data()?['createdAt'],
        identity.createdAt.millisecondsSinceEpoch,
      );
    });

    test('suspendIdentity should update lifecycle in Firestore', () async {
      const id = IdentityId.reconstruct('user_1');
      final identity = Identity.createPending(id: id);
      await repo.createIdentity(identity);

      final result = await repo.suspendIdentity(id, 'Rule violation');
      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('identities').doc(id.value).get();
      final data = doc.data();
      final lifecycle = data?['lifecycle'] as Map<String, dynamic>?;
      expect(lifecycle?['state'], 'disabled');
      expect(lifecycle?['reason'], 'Rule violation');
    });
  });
}
