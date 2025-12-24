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
  final FirestoreIdentityMapper _mapper;

  /// Creates a [FirestoreIdentityRepository].
  ///
  /// [collectionPath] defaults to 'identities'.
  FirestoreIdentityRepository({
    required FirebaseFirestore firestore,
    required FirestoreMessages messages,
    String collectionPath = 'identities',
  })  : _firestore = firestore,
        _collectionPath = collectionPath,
        _messages = messages,
        _mapper = FirestoreIdentityMapper(messages);

  /// Persistence: Saves the identity aggregate to Firestore.
  ///
  /// This is an idempotent UPSERT operation.
  Future<ZenResult<void>> save(Identity identity) async {
    try {
      final docRef = _collection(identity.id.value);
      final data = _mapper.toMap(identity);

      await docRef.set(data);
      return const ZenResult.ok(null);
    } catch (e, stack) {
      // Log identity ID only - no user data or sensitive fields
      ZenLogger.instance.error(
        'Failed to save identity: ${identity.id.value}',
        e,
        stack,
      );
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageOperationFailed(),
          errorCode: InfrastructureErrorCode.storageFailure,
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
        // Log identity ID only - not found is not an error condition
        ZenLogger.instance.warn('Identity not found: ${id.value}');
        return ZenResult.err(
          ZenNotFoundError(_messages.identityNotFound()),
        );
      }

      return _mapper.fromDocument(snapshot);
    } catch (e, stack) {
      // Log identity ID only - no user data or sensitive fields
      ZenLogger.instance.error('Failed to get identity: ${id.value}', e, stack);
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageOperationFailed(),
          errorCode: InfrastructureErrorCode.storageFailure,
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
      // Log identity ID only - no user data or sensitive fields
      ZenLogger.instance.error(
        'Failed to delete identity: ${id.value}',
        e,
        stack,
      );
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageOperationFailed(),
          errorCode: InfrastructureErrorCode.storageFailure,
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
        // Log subject ID only - not found is not an error condition
        ZenLogger.instance.warn('External identity not found: $subject');
        return ZenResult.err(
          ZenNotFoundError(_messages.identityNotFound()),
        );
      }

      final data = snapshot.data();
      if (data == null) {
        // Log subject ID only - indicates data corruption
        ZenLogger.instance.error('Document data is null: $subject');
        return ZenResult.err(
          ZenInfrastructureError(
            _messages.corruptedData(),
            errorCode: InfrastructureErrorCode.corruptedData,
          ),
        );
      }

      return ZenResult.ok(
        FirestoreExternalIdentity(
          subject: snapshot.id,
          claims: _normalizeClaims(data),
        ),
      );
    } catch (e, stack) {
      // Log subject ID only - no user data or sensitive fields
      ZenLogger.instance.error(
        'Failed to fetch external identity: $subject',
        e,
        stack,
      );
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.storageOperationFailed(),
          errorCode: InfrastructureErrorCode.storageFailure,
          originalError: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<ZenResult<IdentityId>> resolveId(ExternalIdentity external) =>
      Future.value(IdentityId.create(external.subject));

  // --- Helpers ---

  /// Normalizes claims to prevent Firestore SDK types from leaking to domain.
  ///
  /// Converts Timestamp objects to ISO 8601 strings.
  Map<String, dynamic> _normalizeClaims(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is Timestamp) {
        normalized[entry.key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        normalized[entry.key] = _normalizeClaims(
          Map<String, dynamic>.from(value),
        );
      } else if (value is List) {
        normalized[entry.key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return _normalizeClaims(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        normalized[entry.key] = value;
      }
    }
    return normalized;
  }

  DocumentReference<Map<String, dynamic>> _collection(String id) =>
      _firestore.collection(_collectionPath).doc(id);
}
