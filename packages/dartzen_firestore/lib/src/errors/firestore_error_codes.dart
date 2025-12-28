import 'package:dartzen_core/dartzen_core.dart' show ZenError;

/// Semantic error codes for Firestore operations.
///
/// These codes are used in [ZenError.internalData] for granular categorization
/// and debugging.
abstract final class FirestoreErrorCodes {
  /// Operation failed due to insufficient permissions.
  static const String permissionDenied = 'firestore/permission-denied';

  /// Document was not found.
  static const String notFound = 'firestore/not-found';

  /// Document already exists.
  static const String alreadyExists = 'firestore/already-exists';

  /// Firestore service is unavailable.
  static const String unavailable = 'firestore/unavailable';

  /// Operation timed out.
  static const String timeout = 'firestore/timeout';

  /// Data is corrupted or in invalid format.
  static const String corruptedData = 'firestore/corrupted-data';

  /// General operation failure.
  static const String operationFailed = 'firestore/operation-failed';

  /// Unknown Firestore error.
  static const String unknown = 'firestore/unknown';
}
