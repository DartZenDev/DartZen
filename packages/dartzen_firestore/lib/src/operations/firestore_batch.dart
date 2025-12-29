import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

import '../errors/firestore_error_mapper.dart';
import '../l10n/firestore_messages.dart';
import '../telemetry/firestore_telemetry.dart';

/// Wrapper around Firestore [WriteBatch] with [ZenResult] support.
///
/// Provides a type-safe API for batch operations with error normalization
/// and optional telemetry.
///
/// Example:
/// ```dart
/// final batch = FirestoreBatch(firestore, localization: localization);
/// batch.set(doc1, {'name': 'Alice'});
/// batch.update(doc2, {'status': 'active'});
/// batch.delete(doc3);
///
/// final result = await batch.commit();
/// ```
final class FirestoreBatch {
  final WriteBatch _batch;
  final FirestoreTelemetry _telemetry;
  final FirestoreMessages _messages;

  int _operationCount = 0;

  /// Creates a [FirestoreBatch].
  ///
  /// [firestore] is the Firestore instance.
  /// [telemetry] is optional telemetry hooks (defaults to no-op).
  /// [localization] is used for error messages.
  /// [language] is the language code for localization (defaults to 'en').
  FirestoreBatch(
    FirebaseFirestore firestore, {
    FirestoreTelemetry telemetry = const NoOpFirestoreTelemetry(),
    required ZenLocalizationService localization,
    String language = 'en',
  }) : _batch = firestore.batch(),
       _telemetry = telemetry,
       _messages = FirestoreMessages(localization, language);

  /// Sets data for a document.
  ///
  /// [ref] is the document reference.
  /// [data] is the document data.
  /// [merge] determines whether to merge with existing data (default: false).
  void set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    if (merge) {
      _batch.set(ref, data, SetOptions(merge: true));
    } else {
      _batch.set(ref, data);
    }
    _operationCount++;
  }

  /// Updates a document.
  ///
  /// [ref] is the document reference.
  /// [data] is the update data.
  void update(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) {
    _batch.update(ref, data);
    _operationCount++;
  }

  /// Deletes a document.
  ///
  /// [ref] is the document reference.
  void delete(DocumentReference<Map<String, dynamic>> ref) {
    _batch.delete(ref);
    _operationCount++;
  }

  /// Commits the batch.
  ///
  /// Returns [ZenResult] with success or normalized error.
  /// Calls telemetry hooks on completion.
  Future<ZenResult<void>> commit({Map<String, dynamic>? metadata}) async {
    final stopwatch = Stopwatch()..start();
    final combinedMetadata = {
      if (metadata != null) ...metadata,
      'batchSize': _operationCount,
    };

    try {
      await _batch.commit();
      stopwatch.stop();

      _telemetry.onBatchCommit(
        _operationCount,
        stopwatch.elapsed,
        metadata: combinedMetadata,
      );
      return const ZenResult.ok(null);
    } catch (e, stack) {
      stopwatch.stop();

      final error = FirestoreErrorMapper.mapException(e, stack, _messages);
      _telemetry.onError('batch_commit', error, metadata: combinedMetadata);

      ZenLogger.instance.error(
        'Firestore batch commit failed',
        error: e,
        stackTrace: stack,
        internalData: combinedMetadata,
      );

      return ZenResult.err(error);
    }
  }
}
