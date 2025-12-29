import 'storage_object.dart';

/// Interface for reading objects from storage.
///
/// This abstraction provides a minimal API for fetching objects by key.
/// It returns raw bytes wrapped in a [StorageObject], or `null` if the
/// object is not found.
///
/// Implementations must:
/// - Return `null` for missing objects (never throw)
/// - Provide object metadata (content type, size)
/// - Log errors internally for debugging
///
/// Example:
/// ```dart
/// final object = await reader.read('data/file.json');
/// if (object != null) {
///   print('Size: ${object.size} bytes');
///   print('Type: ${object.contentType}');
///   print('Content: ${object.asString()}');
/// }
/// ```
// ignore: one_member_abstracts
abstract interface class ZenStorageReader {
  /// Reads an object by key.
  ///
  /// Returns a [StorageObject] containing the object's bytes and metadata,
  /// or `null` if the object is not found.
  ///
  /// This method never throws for "not found" conditions. Other errors
  /// (network failures, permission errors) are logged but return `null`.
  Future<StorageObject?> read(String key);
}
