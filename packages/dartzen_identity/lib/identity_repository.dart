import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

import 'identity_mapper.dart';
import 'identity_models.dart';

/// Firestore-backed repository for [Identity] aggregates.
///
/// Encapsulates all Firestore access for identity management.
final class FirestoreIdentityRepository {
  final FirebaseFirestore _firestore;

  /// Creates a [FirestoreIdentityRepository] with the given [_firestore] instance.
  const FirestoreIdentityRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<ZenFirestoreData> get _collection =>
      _firestore.collection('identities');

  /// Creates a new identity in Firestore.
  Future<ZenResult<void>> createIdentity(Identity identity) async =>
      ZenTry.callAsync(() async {
        try {
          await _collection
              .doc(identity.id.value)
              .set(IdentityMapper.toFirestore(identity));
        } on FirebaseException catch (e) {
          if (e.code == 'already-exists') {
            return const ZenResult<void>.err(
              ZenConflictError('Identity already exists'),
            );
          }
          return ZenResult<void>.err(_mapFirebaseError(e));
        }
      }).then(
        (r) =>
            r.fold((inner) => inner ?? const ZenResult.ok(null), ZenResult.err),
      );

  /// Retrieves an identity by its [id].
  Future<ZenResult<Identity>> getIdentityById(IdentityId id) async {
    final result = await ZenTry.callAsync(() async {
      try {
        final doc = await _collection.doc(id.value).get();
        if (!doc.exists) {
          return ZenResult<Identity>.err(
            ZenNotFoundError('Identity not found: ${id.value}'),
          );
        }
        return IdentityMapper.fromFirestore(doc.id, doc.data()!);
      } on FirebaseException catch (e) {
        return ZenResult<Identity>.err(_mapFirebaseError(e));
      }
    });

    return result.fold((inner) => inner, ZenResult.err);
  }

  /// Updates the roles of an identity.
  Future<ZenResult<void>> changeRoles(
    IdentityId id,
    Authority authority,
  ) async => ZenTry.callAsync(() async {
    try {
      await _collection.doc(id.value).update({
        'authority.roles': authority.roles.map((r) => r.name).toList(),
        'authority.capabilities': authority.capabilities
            .map((c) => c.id)
            .toList(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirebaseError(e);
    }
  });

  /// Marks the identity's email as verified and activates it if pending.
  Future<ZenResult<void>> verifyEmail(IdentityId id) async =>
      ZenTry.callAsync(() async {
        try {
          await _firestore.runTransaction((transaction) async {
            final docRef = _collection.doc(id.value);
            final snapshot = await transaction.get(docRef);

            if (!snapshot.exists) {
              throw _mapFirebaseError(
                FirebaseException(
                  plugin: 'firestore',
                  code: 'not-found',
                  message: 'Identity not found',
                ),
              );
            }

            final identityResult = IdentityMapper.fromFirestore(
              snapshot.id,
              snapshot.data()!,
            );

            await identityResult.fold((identity) async {
              if (identity.lifecycle.state == IdentityState.pending) {
                final activeResult = identity.lifecycle.activate();
                await activeResult.fold((nextLifecycle) async {
                  transaction.update(docRef, {
                    'lifecycle.state': nextLifecycle.state.name,
                    'lifecycle.reason': nextLifecycle.reason,
                  });
                }, (error) => throw Exception(error.message));
              }
            }, (error) => throw Exception(error.message));
          });
        } on FirebaseException catch (e) {
          throw _mapFirebaseError(e);
        }
      });

  /// Suspends the identity with a reason.
  Future<ZenResult<void>> suspendIdentity(IdentityId id, String reason) async {
    final next = IdentityLifecycle.reconstruct(IdentityState.disabled, reason);
    return ZenTry.callAsync(() async {
      try {
        await _collection.doc(id.value).update({
          'lifecycle.state': next.state.name,
          'lifecycle.reason': next.reason,
        });
      } on FirebaseException catch (e) {
        throw _mapFirebaseError(e);
      }
    });
  }

  ZenError _mapFirebaseError(FirebaseException e) => switch (e.code) {
    'permission-denied' => ZenUnauthorizedError(
      e.message ?? 'Permission denied',
    ),
    'not-found' => ZenNotFoundError(e.message ?? 'Document not found'),
    'already-exists' => ZenConflictError(
      e.message ?? 'Document already exists',
    ),
    'resource-exhausted' => ZenUnknownError(
      'Quota exceeded',
      stackTrace: StackTrace.current,
    ),
    'unavailable' => ZenUnknownError(
      'Service unavailable',
      stackTrace: StackTrace.current,
    ),
    _ => ZenUnknownError(
      e.message ?? 'Unknown Firestore error',
      stackTrace: StackTrace.current,
    ),
  };
}
