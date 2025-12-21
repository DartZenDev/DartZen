import 'package:dartzen_core/dartzen_core.dart';

/// Infrastructure-level messages for Firestore adapter.
///
/// These messages are used to wrap low-level Firestore exceptions
/// into semantic [ZenFailure]s.
class FirestoreMessages {
  /// Message when an identity is not found in the database.
  String identityNotFound(String id) => 'Identity not found: $id';

  /// Message when a database connection fails.
  String databaseUnavailable() => 'Database is currently unavailable';

  /// Message when a generic storage error occurs.
  String storageError(String details) => 'Storage error: $details';
}
