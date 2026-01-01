import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:gcloud/datastore.dart';

/// Server-side identity repository using Firestore via gcloud.
///
/// This implementation uses the Firestore emulator for development.
class ServerIdentityRepository {
  /// Creates the repository.
  ServerIdentityRepository({
    required Datastore datastore,
  }) : _datastore = datastore;

  final Datastore _datastore;
  final ZenLogger _logger = ZenLogger.instance;

  static const String _collectionName = 'identities';

  /// Creates or updates an identity.
  Future<ZenResult<IdentityContract>> upsertIdentity({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final key =
          _datastore.emptyKey.append(Key.emptyKey(_collectionName), id: userId);

      final entity = Entity(
        key,
        {
          'userId': userId,
          'email': email,
          'displayName': displayName ?? email.split('@')[0],
          'photoUrl': photoUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await _datastore.commit(inserts: [entity]);

      final identity = IdentityContract(
        id: userId,
        email: email,
        displayName: displayName ?? email.split('@')[0],
        photoUrl: photoUrl,
      );

      _logger.info('Upserted identity: $userId');
      return ZenResult.success(data: identity);
    } catch (e, stackTrace) {
      _logger.error('Failed to upsert identity',
          error: e, stackTrace: stackTrace);
      return ZenResult.failure(
        errorCode: 'identity-upsert-failed',
        errorMessage: 'Failed to create or update identity: $e',
      );
    }
  }

  /// Retrieves an identity by user ID.
  Future<ZenResult<IdentityContract>> getIdentity(String userId) async {
    try {
      final key =
          _datastore.emptyKey.append(Key.emptyKey(_collectionName), id: userId);
      final results = await _datastore.lookup([key]);

      if (results.isEmpty) {
        return ZenResult.failure(
          errorCode: 'identity-not-found',
          errorMessage: 'Identity not found: $userId',
        );
      }

      final entity = results.first;
      final identity = IdentityContract(
        id: entity.properties['userId'] as String,
        email: entity.properties['email'] as String,
        displayName: entity.properties['displayName'] as String?,
        photoUrl: entity.properties['photoUrl'] as String?,
      );

      return ZenResult.success(data: identity);
    } catch (e, stackTrace) {
      _logger.error('Failed to get identity', error: e, stackTrace: stackTrace);
      return ZenResult.failure(
        errorCode: 'identity-fetch-failed',
        errorMessage: 'Failed to retrieve identity: $e',
      );
    }
  }

  /// Deletes an identity.
  Future<ZenResult<void>> deleteIdentity(String userId) async {
    try {
      final key =
          _datastore.emptyKey.append(Key.emptyKey(_collectionName), id: userId);
      await _datastore.commit(deletes: [key]);

      _logger.info('Deleted identity: $userId');
      return ZenResult.success(data: null);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete identity',
          error: e, stackTrace: stackTrace);
      return ZenResult.failure(
        errorCode: 'identity-delete-failed',
        errorMessage: 'Failed to delete identity: $e',
      );
    }
  }
}
