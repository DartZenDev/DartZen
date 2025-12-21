/// Infrastructure-level messages for Firestore adapter.
///
/// These messages provide semantic, user-facing error messages
/// without leaking internal implementation details.
abstract class FirestoreMessages {
  /// User-facing message when an identity is not found.
  static String identityNotFound() =>
      'The requested identity could not be found.';

  /// User-facing message when database is unavailable.
  static String databaseUnavailable() =>
      'The database service is currently unavailable. Please try again later.';

  /// User-facing message for storage operation failures.
  static String storageOperationFailed() =>
      'The storage operation could not be completed.';

  /// User-facing message for permission denied errors.
  static String permissionDenied() =>
      'You do not have permission to perform this operation.';

  /// User-facing message for timeout errors.
  static String operationTimeout() =>
      'The operation took too long and has been cancelled.';

  /// User-facing message for corrupted data.
  static String corruptedData() =>
      'The stored data appears to be invalid or corrupted.';
}
