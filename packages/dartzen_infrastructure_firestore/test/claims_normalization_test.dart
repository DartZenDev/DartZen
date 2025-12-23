import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_firestore/dartzen_infrastructure_firestore.dart';
import 'package:dartzen_infrastructure_firestore/src/models/infrastructure_errors.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('FirestoreIdentityRepository - Claims Normalization', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreIdentityRepository(
        firestore: firestore,
        messages: createTestMessages(),
      );
    });

    test('getIdentity normalizes Timestamp values to ISO strings', () async {
      // Setup: Add a document with Timestamp
      await firestore.collection('identities').doc('test-user').set({
        'lifecycle_state': 'active',
        'created_at': Timestamp.now(),
        'last_login': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'metadata': {'verified_at': Timestamp.fromDate(DateTime(2024, 1, 10))},
      });

      final result = await repository.getIdentity('test-user');

      expect(result.isSuccess, isTrue);
      final externalIdentity = result.dataOrNull!;

      // Assert: Timestamps are converted to ISO strings
      expect(externalIdentity.claims['created_at'], isA<String>());
      expect(externalIdentity.claims['last_login'], isA<String>());
      expect(externalIdentity.claims['metadata'], isA<Map<String, dynamic>>());
      final metadata =
          externalIdentity.claims['metadata'] as Map<String, dynamic>;
      expect(metadata['verified_at'], isA<String>());

      // Assert: No Timestamp objects leak
      void assertNoTimestamps(dynamic value) {
        if (value is Map) {
          for (final v in value.values) {
            assertNoTimestamps(v);
          }
        } else if (value is List) {
          for (final v in value) {
            assertNoTimestamps(v);
          }
        } else {
          expect(value is! Timestamp, isTrue);
        }
      }

      assertNoTimestamps(externalIdentity.claims);
    });

    test('getIdentity normalizes Timestamps in nested lists', () async {
      await firestore.collection('identities').doc('user-with-list').set({
        'lifecycle_state': 'pending',
        'events': [
          {'timestamp': Timestamp.now(), 'type': 'login'},
          {'timestamp': Timestamp.now(), 'type': 'logout'},
        ],
      });

      final result = await repository.getIdentity('user-with-list');

      expect(result.isSuccess, isTrue);
      final claims = result.dataOrNull!.claims;
      final events = claims['events'] as List;

      for (final event in events) {
        final eventMap = event as Map<String, dynamic>;
        expect(eventMap['timestamp'], isA<String>());
        expect(eventMap['timestamp'] is! Timestamp, isTrue);
      }
    });
  });

  group('FirestoreIdentityRepository - Stable Lifecycle Tokens', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreIdentityRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreIdentityRepository(
        firestore: firestore,
        messages: createTestMessages(),
      );
    });

    test('stable tokens remain consistent across enum renames', () async {
      // This test documents that we use stable tokens, not enum.name
      // If IdentityState enum is renamed, these tokens must not change

      final testCases = {
        'pending': 'pending',
        'active': 'active',
        'revoked': 'revoked',
        'disabled': 'disabled',
      };

      for (final entry in testCases.entries) {
        await firestore.collection('identities').doc('user-${entry.key}').set({
          'lifecycle_state': entry.value,
          'roles': <String>[],
          'capabilities': <String>[],
          'created_at': Timestamp.now(),
        });

        final getResult = await repository.get(
          IdentityId.create('user-${entry.key}').dataOrNull!,
        );

        expect(getResult.isSuccess, isTrue);
      }
    });

    test('unknown lifecycle token returns error with correct code', () async {
      await firestore.collection('identities').doc('invalid-user').set({
        'lifecycle_state': 'unknown_state',
        'roles': <String>[],
        'capabilities': <String>[],
        'created_at': Timestamp.now(),
      });

      final result = await repository.get(
        IdentityId.create('invalid-user').dataOrNull!,
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull! as ZenInfrastructureError;
      expect(
        error.internalData?['errorCode'],
        InfrastructureErrorCode.corruptedData,
      );
    });
  });
}
