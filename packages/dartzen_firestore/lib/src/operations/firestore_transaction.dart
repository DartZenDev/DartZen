import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

import '../connection/firestore_connection.dart';
import '../converters/firestore_converters.dart';
import '../errors/firestore_error_mapper.dart';
import '../firestore_types.dart';
import '../l10n/firestore_messages.dart';
import '../telemetry/firestore_telemetry.dart';

/// Transaction helper for REST API.
final class Transaction {
  /// The transaction ID.
  final String id;
  final List<Map<String, dynamic>> _writes = [];

  /// Creates a [Transaction] with the given [id].
  Transaction(this.id);

  /// Retrieves a document by its path within the transaction.
  Future<ZenFirestoreDocument> get(String path) async =>
      await FirestoreConnection.client.getDocument(path, transactionId: id);

  /// Sets data for a document.
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
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
    _writes.add({
      'delete':
          'projects/${FirestoreConnection.client.projectId}/databases/(default)/documents/$path',
    });
  }
}

/// Helper for running Firestore transactions with [ZenResult] support.
abstract final class FirestoreTransaction {
  /// Runs a Firestore transaction.
  static Future<ZenResult<T>> run<T>(
    Future<ZenResult<T>> Function(Transaction transaction) operation, {
    FirestoreTelemetry telemetry = const NoOpFirestoreTelemetry(),
    required ZenLocalizationService localization,
    String language = 'en',
    Map<String, dynamic>? metadata,
  }) async {
    final messages = FirestoreMessages(localization, language);
    final stopwatch = Stopwatch()..start();

    try {
      final transactionId = await FirestoreConnection.client.beginTransaction();
      final transaction = Transaction(transactionId);

      final result = await operation(transaction);

      if (result.isSuccess) {
        await FirestoreConnection.client.commit(
          transaction._writes,
          transactionId: transactionId,
        );
      }

      stopwatch.stop();
      telemetry.onTransactionComplete(
        stopwatch.elapsed,
        result.isSuccess,
        metadata: metadata,
      );

      return result;
    } catch (e, stack) {
      stopwatch.stop();
      final error = FirestoreErrorMapper.mapException(e, stack, messages);
      telemetry.onTransactionComplete(
        stopwatch.elapsed,
        false,
        metadata: metadata,
      );
      telemetry.onError('transaction', error, metadata: metadata);

      ZenLogger.instance.error(
        'Firestore transaction failed',
        error: e,
        stackTrace: stack,
        internalData: metadata,
      );

      return ZenResult<T>.err(error);
    }
  }
}
