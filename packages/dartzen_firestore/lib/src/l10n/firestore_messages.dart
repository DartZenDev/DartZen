import 'package:dartzen_localization/dartzen_localization.dart';

/// Message accessor for Firestore error messages.
///
/// Uses [ZenLocalizationService] to retrieve localized error messages.
class FirestoreMessages {
  final ZenLocalizationService _localization;
  final String _language;

  /// Creates a [FirestoreMessages] instance.
  const FirestoreMessages(this._localization, this._language);

  /// Returns localized message for permission denied error.
  String permissionDenied() => _localization.translate(
    'firestore.error.permission_denied',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for document not found error.
  String notFound() => _localization.translate(
    'firestore.error.not_found',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for operation timeout.
  String timeout() => _localization.translate(
    'firestore.error.timeout',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for unavailable service.
  String unavailable() => _localization.translate(
    'firestore.error.unavailable',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for corrupted or invalid data.
  String corruptedData() => _localization.translate(
    'firestore.error.corrupted_data',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for a generic operation failure.
  String operationFailed() => _localization.translate(
    'firestore.error.operation_failed',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for an unknown error.
  String unknown() => _localization.translate(
    'firestore.error.unknown',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for emulator connection status.
  String emulatorConnection(String host, int port) => _localization.translate(
    'firestore.connection.emulator',
    language: _language,
    module: 'firestore',
    params: {'host': host, 'port': port.toString()},
  );

  /// Returns localized message for production connection status.
  String productionConnection() => _localization.translate(
    'firestore.connection.production',
    language: _language,
    module: 'firestore',
  );

  /// Returns localized message for unavailable emulator connection.
  String emulatorUnavailable(String host, int port) => _localization.translate(
    'firestore.connection.emulator_unavailable',
    language: _language,
    module: 'firestore',
    params: {'host': host, 'port': port.toString()},
  );
}
