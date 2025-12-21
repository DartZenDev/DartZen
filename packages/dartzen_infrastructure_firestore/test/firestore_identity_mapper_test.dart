import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/src/firestore_identity_mapper.dart';
import 'package:dartzen_infrastructure_firestore/src/models/infrastructure_errors.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreIdentityMapper', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    final testId = IdentityId.create('test-id').dataOrNull!;
    final testCreated = ZenTimestamp.now();
    final testIdentity = Identity(
      id: testId,
      lifecycle: IdentityLifecycle.initial(),
      authority: Authority(
        roles: {const Role('admin')},
        capabilities: {const Capability('read')},
      ),
      createdAt: testCreated,
    );

    test('toMap converts Identity to Firestore map correctly', () {
      final map = FirestoreIdentityMapper.toMap(testIdentity);

      expect(map['lifecycle_state'], 'pending');
      expect(map['roles'], contains('admin'));
      expect(map['capabilities'], contains('read'));
      expect(map['created_at'], isA<Timestamp>());
    });

    test('fromDocument maps valid document to Identity', () async {
      await firestore.collection('identities').doc('test-id').set({
        'lifecycle_state': 'pending',
        'roles': ['admin'],
        'capabilities': ['read'],
        'created_at': Timestamp.fromMillisecondsSinceEpoch(
          testCreated.value.millisecondsSinceEpoch,
        ),
      });

      final doc = await firestore.collection('identities').doc('test-id').get();
      final result = FirestoreIdentityMapper.fromDocument(doc);

      expect(result.isSuccess, isTrue);
      final identity = result.dataOrNull!;

      expect(identity.id, testId);
      expect(identity.lifecycle.state, IdentityState.pending);
      expect(identity.authority.roles.first.name, 'admin');
    });

    test('fromDocument handles missing document failure', () async {
      final doc = await firestore
          .collection('identities')
          .doc('missing-id')
          .get();
      final result = FirestoreIdentityMapper.fromDocument(doc);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenInfrastructureError>());
    });

    test('fromDocument reconstructs active lifecycle', () async {
      await firestore.collection('identities').doc('active-id').set({
        'lifecycle_state': 'active',
        'roles': <String>[],
        'capabilities': <String>[],
        'created_at': Timestamp.now(),
      });

      final doc = await firestore
          .collection('identities')
          .doc('active-id')
          .get();
      final result = FirestoreIdentityMapper.fromDocument(doc);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.lifecycle.state, IdentityState.active);
    });

    test('fromDocument reconstructs revoked lifecycle with reason', () async {
      await firestore.collection('identities').doc('revoked-id').set({
        'lifecycle_state': 'revoked',
        'lifecycle_reason': 'TOS violation',
        'roles': <String>[],
        'capabilities': <String>[],
        'created_at': Timestamp.now(),
      });

      final doc = await firestore
          .collection('identities')
          .doc('revoked-id')
          .get();
      final result = FirestoreIdentityMapper.fromDocument(doc);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.lifecycle.state, IdentityState.revoked);
      expect(result.dataOrNull!.lifecycle.reason, 'TOS violation');
    });
  });
}
