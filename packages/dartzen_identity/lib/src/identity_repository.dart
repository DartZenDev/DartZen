import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

import 'identity_mapper.dart';
import 'identity_models.dart';

/// Firestore-backed repository for [Identity] aggregates using REST API.
///
/// Encapsulates all Firestore access for identity management.
final class FirestoreIdentityRepository {
  final ZenLocalizationService _localization;

  /// Creates a [FirestoreIdentityRepository].
  const FirestoreIdentityRepository({
    required ZenLocalizationService localization,
  }) : _localization = localization;

  String _docPath(String id) => 'identities/$id';

  /// Creates a new identity in Firestore.
  Future<ZenResult<void>> createIdentity(Identity identity) async =>
      ZenTry.callAsync(() async {
        try {
          final batch = FirestoreBatch(localization: _localization);
          batch.set(
            _docPath(identity.id.value),
            IdentityMapper.toFirestore(identity),
          );
          return await batch.commit();
        } catch (e, stack) {
          return ZenResult<void>.err(
            ZenUnknownError(e.toString(), stackTrace: stack),
          );
        }
      }).then((r) => r.fold((inner) => inner, ZenResult.err));

  /// Retrieves an identity by its [id].
  Future<ZenResult<Identity>> getIdentityById(IdentityId id) async =>
      ZenTry.callAsync(() async {
        try {
          final doc = await FirestoreConnection.client.getDocument(
            _docPath(id.value),
          );
          if (!doc.exists) {
            return ZenResult<Identity>.err(
              ZenNotFoundError('Identity not found: ${id.value}'),
            );
          }
          return IdentityMapper.fromFirestore(doc.id, doc.data!);
        } catch (e, stack) {
          return ZenResult<Identity>.err(
            ZenUnknownError(e.toString(), stackTrace: stack),
          );
        }
      }).then((r) => r.fold((inner) => inner, ZenResult.err));

  /// Updates the roles of an identity.
  Future<ZenResult<void>> changeRoles(
    IdentityId id,
    Authority authority,
  ) async => ZenTry.callAsync(() async {
    try {
      await FirestoreConnection.client.patchDocument(_docPath(id.value), {
        'authority.roles': authority.roles.map((r) => r.name).toList(),
        'authority.capabilities': authority.capabilities
            .map((c) => c.id)
            .toList(),
      });
      return const ZenResult<void>.ok(null);
    } catch (e, stack) {
      return ZenResult<void>.err(
        ZenUnknownError(e.toString(), stackTrace: stack),
      );
    }
  }).then((r) => r.fold((inner) => inner, ZenResult.err));

  /// Marks the identity's email as verified and activates it if pending.
  Future<ZenResult<void>> verifyEmail(
    IdentityId id,
  ) async => ZenTry.callAsync(() async {
    try {
      final doc = await FirestoreConnection.client.getDocument(
        _docPath(id.value),
      );
      if (!doc.exists) {
        return const ZenResult<void>.err(
          ZenNotFoundError('Identity not found'),
        );
      }

      final identityResult = IdentityMapper.fromFirestore(doc.id, doc.data!);
      return await identityResult.fold((identity) async {
        if (identity.lifecycle.state == IdentityState.pending) {
          final activeResult = identity.lifecycle.activate();
          return await activeResult.fold((nextLifecycle) async {
            await FirestoreConnection.client.patchDocument(_docPath(id.value), {
              'lifecycle.state': nextLifecycle.state.name,
              'lifecycle.reason': nextLifecycle.reason,
            });
            return const ZenResult<void>.ok(null);
          }, (error) async => ZenResult<void>.err(error));
        }
        return const ZenResult<void>.ok(null);
      }, (error) async => ZenResult<void>.err(error));
    } catch (e, stack) {
      return ZenResult<void>.err(
        ZenUnknownError(e.toString(), stackTrace: stack),
      );
    }
  }).then((r) => r.fold((inner) => inner, ZenResult.err));

  /// Suspends the identity with a reason.
  Future<ZenResult<void>> suspendIdentity(IdentityId id, String reason) async {
    final next = IdentityLifecycle.reconstruct(IdentityState.disabled, reason);
    return ZenTry.callAsync(() async {
      try {
        await FirestoreConnection.client.patchDocument(_docPath(id.value), {
          'lifecycle.state': next.state.name,
          'lifecycle.reason': next.reason,
        });
        return const ZenResult<void>.ok(null);
      } catch (e, stack) {
        return ZenResult<void>.err(
          ZenUnknownError(e.toString(), stackTrace: stack),
        );
      }
    }).then((r) => r.fold((inner) => inner, ZenResult.err));
  }
}
