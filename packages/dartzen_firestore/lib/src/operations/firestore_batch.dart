import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

import '../connection/firestore_connection.dart';
import '../converters/firestore_converters.dart';
import '../errors/firestore_error_mapper.dart';
import '../l10n/firestore_messages.dart';
import '../telemetry/firestore_telemetry.dart';

/// Wrapper around Firestore REST commit endpoint with [ZenResult] support.
///
/// Collects write operations and executes them in a single batch.
/// Subject to 500 operations limit.
final class FirestoreBatch {
  final List<Map<String, dynamic>> _writes = [];
  final FirestoreTelemetry _telemetry;
  final FirestoreMessages _messages;

  /// Creates a [FirestoreBatch].
  FirestoreBatch({
    FirestoreTelemetry telemetry = const NoOpFirestoreTelemetry(),
    required ZenLocalizationService localization,
    String language = 'en',
  }) : _telemetry = telemetry,
       _messages = FirestoreMessages(localization, language);

  /// Sets data for a document.
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    if (_writes.length >= 500) {
      throw StateError('Batch operation limit exceeded (max 500).');
    }

    final fields = FirestoreConverters.dataToFields(data);
    _writes.add({
      'update': {
        'name':
            'projects/${FirestoreConnection.client.projectId}/databases/(default)/documents/$path',
        'fields': fields,
      },
      if (!merge) 'currentDocument': {'exists': false},
    });
  }

  /// Updates a document.
  void update(String path, Map<String, dynamic> data) {
    if (_writes.length >= 500) {
      throw StateError('Batch operation limit exceeded (max 500).');
    }

    final fields = FirestoreConverters.dataToFields(data);
    _writes.add({
      'update': {
        'name':
            'projects/${FirestoreConnection.client.projectId}/databases/(default)/documents/$path',
        'fields': fields,
      },
      'currentDocument': {'exists': true},
    });
  }

  /// Deletes a document.
  void delete(String path) {
    if (_writes.length >= 500) {
      throw StateError('Batch operation limit exceeded (max 500).');
    }

    _writes.add({
      'delete':
          'projects/${FirestoreConnection.client.projectId}/databases/(default)/documents/$path',
    });
  }

  /// Commits the batch.
  Future<ZenResult<void>> commit({Map<String, dynamic>? metadata}) async {
    if (_writes.isEmpty) return const ZenResult.ok(null);

    final stopwatch = Stopwatch()..start();
    final combinedMetadata = {
      if (metadata != null) ...metadata,
      'batchSize': _writes.length,
    };

    try {
      await FirestoreConnection.client.commit(_writes);
      stopwatch.stop();

      _telemetry.onBatchCommit(
        _writes.length,
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
