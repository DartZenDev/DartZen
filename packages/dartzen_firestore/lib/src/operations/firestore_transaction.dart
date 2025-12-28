import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/src/errors/firestore_error_mapper.dart';
import 'package:dartzen_firestore/src/l10n/firestore_messages.dart';
import 'package:dartzen_firestore/src/telemetry/firestore_telemetry.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Helper for running Firestore transactions with [ZenResult] support.
///
/// Provides error normalization and optional telemetry for transactions.
///
/// Example:
/// ```dart
/// final result = await FirestoreTransaction.run<int>(
///   firestore,
///   (Transaction transaction) async {
///     final docRef = firestore.collection('counters').doc('global');
///     final snapshot = await transaction.get(docRef);
///     final newValue = (snapshot.data()?['value'] as int? ?? 0) + 1;
///     transaction.update(docRef, {'value': newValue});
///     return ZenResult.ok(newValue);
///   },
///   localization: localization,
/// );
/// ```
abstract final class FirestoreTransaction {
  /// Runs a Firestore transaction.
  ///
  /// [firestore] is the Firestore instance.
  /// [operation] is the transaction function that returns [ZenResult].
  /// [telemetry] is optional telemetry hooks (defaults to no-op).
  /// [localization] is used for error messages.
  /// [language] is the language code for localization (defaults to 'en').
  /// [metadata] is optional metadata for telemetry.
  ///
  /// Returns [ZenResult] with the operation result or normalized error.
  static Future<ZenResult<T>> run<T>(
    FirebaseFirestore firestore,
    Future<ZenResult<T>> Function(Transaction transaction) operation, {
    FirestoreTelemetry telemetry = const NoOpFirestoreTelemetry(),
    required ZenLocalizationService localization,
    String language = 'en',
    Map<String, dynamic>? metadata,
  }) async {
    final messages = FirestoreMessages(localization, language);
    final stopwatch = Stopwatch()..start();

    try {
      final result = await firestore.runTransaction<ZenResult<T>>((
        Transaction transaction,
      ) async {
        try {
          return await operation(transaction);
        } catch (e, stack) {
          // Catch errors inside the transaction function
          final error = FirestoreErrorMapper.mapException(e, stack, messages);
          return ZenResult<T>.err(error);
        }
      });

      stopwatch.stop();
      final success = result.isSuccess;

      telemetry.onTransactionComplete(
        stopwatch.elapsed,
        success,
        metadata: metadata,
      );

      if (!success) {
        ZenLogger.instance.warn(
          'Firestore transaction completed with failure',
          internalData: {
            'error': result.errorOrNull,
            if (metadata != null) ...metadata,
          },
        );
      }

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
