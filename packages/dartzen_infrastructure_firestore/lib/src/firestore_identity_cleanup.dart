import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

import 'l10n/firestore_messages.dart';
import 'models/infrastructure_errors.dart';

/// Firestore-based implementation of [IdentityCleanup].
///
/// Provides explicit cleanup operations for expired or unverified identities.
/// Does NOT run automatically - must be invoked externally.
class FirestoreIdentityCleanup implements IdentityCleanup {
  final FirebaseFirestore _firestore;
  final String _collectionPath;
  final FirestoreMessages _messages;

  /// Creates a [FirestoreIdentityCleanup].
  ///
  /// [collectionPath] defaults to 'identities'.
  FirestoreIdentityCleanup({
    required FirebaseFirestore firestore,
    required FirestoreMessages messages,
    String collectionPath = 'identities',
  })  : _firestore = firestore,
        _collectionPath = collectionPath,
        _messages = messages;

  @override
  Future<ZenResult<int>> cleanupExpiredIdentities(ZenTimestamp before) async {
    // Log operation start with timestamp only - no user identifiers
    ZenLogger.instance.info(
      'Starting cleanup of identities created before: ${before.value}',
    );

    try {
      final beforeTimestamp = Timestamp.fromMillisecondsSinceEpoch(
        before.value.millisecondsSinceEpoch,
      );

      // Query identities created before the cutoff and in pending state
      final query = _firestore
          .collection(_collectionPath)
          .where('created_at', isLessThan: beforeTimestamp)
          .where('lifecycle_state', isEqualTo: 'pending');

      final snapshot = await query.get();
      final deletedCount = snapshot.docs.length;

      // Firestore batch writes are limited to 500 operations
      // Process in batches to handle large datasets safely
      const batchSize = 500;
      var processed = 0;

      while (processed < snapshot.docs.length) {
        final batch = _firestore.batch();
        final endIndex = (processed + batchSize < snapshot.docs.length)
            ? processed + batchSize
            : snapshot.docs.length;

        for (var i = processed; i < endIndex; i++) {
          final doc = snapshot.docs[i];
          batch.delete(doc.reference);
          // Log document ID only - no user data or sensitive fields
          ZenLogger.instance.debug('Marked for cleanup: ${doc.id}');
        }

        await batch.commit();
        processed = endIndex;
      }

      // Log summary with count only - no specific identifiers
      ZenLogger.instance.info(
        'Cleanup completed: $deletedCount identities removed',
      );
      return ZenResult.ok(deletedCount);
    } catch (e, stack) {
      // Error logging contains no user data - only operation context
      ZenLogger.instance.error('Cleanup operation failed', e, stack);
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
}
