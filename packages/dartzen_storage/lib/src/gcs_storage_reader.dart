import 'package:dartzen_core/dartzen_core.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;

import 'storage_object.dart';
import 'zen_storage_reader.dart';

/// A [ZenStorageReader] backed by Google Cloud Storage.
///
/// This reader fetches objects from a GCS bucket using the official
/// `gcloud` package. Configuration is fully explicit and requires:
/// - A configured [Storage] client
/// - A bucket name
/// - An optional object prefix
///
/// Example:
/// ```dart
/// final storage = Storage(authClient, project);
/// final reader = GcsStorageReader(
///   storage: storage,
///   bucket: 'my-content-bucket',
///   prefix: 'data/',
/// );
///
/// final object = await reader.read('file.json');
/// if (object != null) {
///   print(object.asString());
/// }
/// ```
///
/// The reader returns:
/// - A [StorageObject] when found
/// - `null` when not found (404 error)
/// - Throws exceptions for all other errors (permissions, network, etc.)
///
/// This follows the Fail Fast principle: configuration errors and system
/// failures propagate immediately rather than being silently converted to null.
class GcsStorageReader implements ZenStorageReader {
  /// Creates a [GcsStorageReader].
  ///
  /// The [storage] client must be configured with appropriate credentials.
  /// The [bucket] is the GCS bucket name.
  /// The [prefix] is an optional object key prefix (e.g., 'data/').
  const GcsStorageReader({
    required Storage storage,
    required String bucket,
    String? prefix,
  }) : _storage = storage,
       _bucket = bucket,
       _prefix = prefix;

  final Storage _storage;
  final String _bucket;
  final String? _prefix;

  /// Reads an object from Google Cloud Storage by key.
  ///
  /// Returns a [StorageObject] when found, or `null` when not found (404).
  ///
  /// Throws exceptions for:
  /// - Permission errors (403)
  /// - Network failures
  /// - Misconfiguration (wrong bucket, invalid credentials)
  /// - Any other system errors
  ///
  /// This ensures the system fails fast when misconfigured rather than
  /// silently returning null for all errors.
  @override
  Future<StorageObject?> read(String key) async {
    try {
      final objectName = _prefix != null ? '$_prefix$key' : key;
      final bucket = _storage.bucket(_bucket);

      final bytes = <int>[];
      String? contentType;

      await for (final chunk in bucket.read(objectName)) {
        bytes.addAll(chunk);
      }

      // Attempt to get metadata for content type
      try {
        final info = await bucket.info(objectName);
        contentType = info.metadata.contentType;
      } catch (_) {
        // Metadata fetch failed, continue without content type
      }

      return StorageObject(bytes: bytes, contentType: contentType);
    } on storage_api.DetailedApiRequestError catch (e) {
      // Only return null for 404 Not Found
      if (e.status == 404) {
        ZenLogger.instance.info(
          'Object not found in GCS',
          internalData: {'bucket': _bucket, 'key': key},
        );
        return null;
      }
      // All other API errors should propagate (403, 500, etc.)
      rethrow;
    } catch (e) {
      // Network errors, configuration errors, etc. should propagate
      rethrow;
    }
  }
}
