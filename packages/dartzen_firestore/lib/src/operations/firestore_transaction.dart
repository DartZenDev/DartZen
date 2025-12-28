import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/src/errors/firestore_error_mapper.dart';
import 'package:dartzen_firestore/src/l10n/firestore_messages.dart';
import 'package:dartzen_firestore/src/telemetry/firestore_telemetry.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Helper for running Firestore transactions with [ZenResult] support.
///
/// Provides error normalization and optional telemetry for transactions.
abstract final class FirestoreTransaction {
  /// Runs a Firestore transaction.
  ///
  /// [firestore] is the Firestore instance.
  /// [operation] is the transaction function that returns [ZenResult].
  /// [telemetry] is optional telemetry hooks (defaults to no-op).
  /// [localization] is used for error messages.
  /// [language] is the language code for localization (defaults to 'en').
  ///
  /// Returns [ZenResult] with the operation result or normalized error.
  static Future<ZenResult<T>> run<T>(
    FirebaseFirestore firestore,
    Future<ZenResult<T>> Function(Transaction transaction) operation, {
    FirestoreTelemetry telemetry = const NoOpFirestoreTelemetry(),
    required ZenLocalizationService localization,
    String language = 'en',
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

      telemetry.onTransactionComplete(stopwatch.elapsed, success);

      if (!success) {
        ZenLogger.instance.warn(
          'Firestore transaction completed with failure: ${result.errorOrNull}',
        );
      }

      return result;
    } catch (e, stack) {
      stopwatch.stop();

      final error = FirestoreErrorMapper.mapException(e, stack, messages);
      telemetry.onTransactionComplete(stopwatch.elapsed, false);
      telemetry.onError('transaction', error);

      ZenLogger.instance.error('Firestore transaction failed', e, stack);

      return ZenResult<T>.err(error);
    }
  }
}
