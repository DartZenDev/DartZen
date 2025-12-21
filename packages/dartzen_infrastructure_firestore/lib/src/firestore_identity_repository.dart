import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

import 'firestore_identity_mapper.dart';
import 'l10n/firestore_messages.dart';
import 'models/firestore_external_identity.dart';
import 'models/infrastructure_errors.dart';

/// Concrete implementation of an Identity Repository using Cloud Firestore.
///
/// Implements [IdentityProvider] for domain discovery and resolution.
/// Exposes [save] and [delete] for application-layer state mutations.
class FirestoreIdentityRepository implements IdentityProvider {
  final FirebaseFirestore _firestore;
  final String _collectionPath;
  final FirestoreMessages _messages;

  /// Creates a [FirestoreIdentityRepository].
  ///
  /// [collectionPath] defaults to 'identities'.
  FirestoreIdentityRepository({
    required FirebaseFirestore firestore,
    String collectionPath = 'identities',
  }) : _firestore = firestore,
       _collectionPath = collectionPath,
       _messages = FirestoreMessages();

  /// Persistence: Saves the identity aggregate to Firestore.
  ///
  /// This is an idempotent UPSERT operation.
  Future<ZenResult<void>> save(Identity identity) async {
    try {
      final docRef = _collection(identity.id.value);
      final data = FirestoreIdentityMapper.toMap(identity);

      await docRef.set(data);
      return const ZenResult.ok(null);
    } catch (e, stack) {
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageError('Failed to save identity'),
          originalError: e,
          stackTrace: stack,
        ),
      );
    }
  }

  /// Persistence: Retrieves an identity by its ID.
  Future<ZenResult<Identity>> get(IdentityId id) async {
    try {
      final docRef = _collection(id.value);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        return ZenResult.err(
          ZenNotFoundError(_messages.identityNotFound(id.value)),
        );
      }

      return FirestoreIdentityMapper.fromDocument(snapshot);
    } catch (e, stack) {
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageError('Failed to get identity'),
          originalError: e,
          stackTrace: stack,
        ),
      );
    }
  }

  /// Persistence: Deletes an identity by its ID.
  Future<ZenResult<void>> delete(IdentityId id) async {
    try {
      final docRef = _collection(id.value);
      await docRef.delete();
      return const ZenResult.ok(null);
    } catch (e, stack) {
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageError('Failed to delete identity'),
          originalError: e,
          stackTrace: stack,
        ),
      );
    }
  }

  // --- IdentityProvider Implementation ---

  @override
  Future<ZenResult<ExternalIdentity>> getIdentity(String subject) async {
    // In this adapter, we assume subject == IdentityId == Document ID.
    try {
      final docRef = _collection(subject);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        return ZenResult.err(
          ZenNotFoundError(_messages.identityNotFound(subject)),
        );
      }

      final data = snapshot.data();
      if (data == null) {
        return ZenResult.err(
          ZenInfrastructureError(
            _messages.storageError('Document data is null'),
          ),
        );
      }

      return ZenResult.ok(
        FirestoreExternalIdentity(subject: snapshot.id, claims: data),
      );
    } catch (e, stack) {
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageError('Failed to fetch external identity'),
          originalError: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<ZenResult<IdentityId>> resolveId(ExternalIdentity external) async =>
      IdentityId.create(external.subject);

  // --- Helpers ---

  DocumentReference<Map<String, dynamic>> _collection(String id) =>
      _firestore.collection(_collectionPath).doc(id);
}
