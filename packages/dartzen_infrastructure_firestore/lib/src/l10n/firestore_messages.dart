import 'package:dartzen_localization/dartzen_localization.dart';

/// Typed messages accessor for the 'firestore' module.
class FirestoreMessages {
  /// Creates a [FirestoreMessages] wrapper.
  const FirestoreMessages(this._service, this._language);

  final ZenLocalizationService _service;
  final String _language;

  /// User-facing message when an identity is not found.
  String identityNotFound() => _t('firestore.error.identity_not_found');

  /// User-facing message when database is unavailable.
  String databaseUnavailable() => _t('firestore.error.database_unavailable');

  /// User-facing message for storage operation failures.
  String storageOperationFailed() =>
      _t('firestore.error.storage_operation_failed');

  /// User-facing message for permission denied errors.
  String permissionDenied() => _t('firestore.error.permission_denied');

  /// User-facing message for timeout errors.
  String operationTimeout() => _t('firestore.error.operation_timeout');

  /// User-facing message for corrupted data.
  String corruptedData() => _t('firestore.error.corrupted_data');

  /// User-facing message when a document does not exist.
  String documentNotFound() => _t('firestore.error.document_not_found');

  /// User-facing message when document data is null.
  String documentDataNull() => _t('firestore.error.document_data_null');

  /// User-facing message when lifecycle state is missing.
  String missingLifecycleState() =>
      _t('firestore.error.missing_lifecycle_state');

  /// User-facing message when lifecycle state is unknown.
  String unknownLifecycleState() =>
      _t('firestore.error.unknown_lifecycle_state');

  /// User-facing message when timestamp is missing.
  String missingTimestamp() => _t('firestore.error.missing_timestamp');

  /// Helper to reduce boilerplate.
  String _t(String key) =>
      _service.translate(key, language: _language, module: 'firestore');
}
