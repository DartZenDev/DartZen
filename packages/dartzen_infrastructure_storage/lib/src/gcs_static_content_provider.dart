import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_server/dartzen_server.dart';
import 'package:gcloud/storage.dart';

/// A [ZenStaticContentProvider] backed by Google Cloud Storage.
///
/// This provider fetches static content from a GCS bucket.
/// Configuration is fully explicit and requires:
/// - A configured [Storage] client
/// - A bucket name
/// - An optional object prefix
///
/// Example:
/// ```dart
/// final storage = Storage(authClient, project);
/// final provider = GcsStaticContentProvider(
///   storage: storage,
///   bucket: 'my-static-content',
///   prefix: 'public/',
/// );
/// ```
///
/// The provider returns:
/// - Content as-is when found
/// - `null` when not found
/// - Never throws for "not found" conditions
class GcsStaticContentProvider implements ZenStaticContentProvider {
  /// Creates a [GcsStaticContentProvider].
  ///
  /// The [storage] client must be configured with appropriate credentials.
  /// The [bucket] is the GCS bucket name.
  /// The [prefix] is an optional object key prefix (e.g., 'public/').
  const GcsStaticContentProvider({
    required Storage storage,
    required String bucket,
    String? prefix,
  }) : _storage = storage,
       _bucket = bucket,
       _prefix = prefix;

  final Storage _storage;
  final String _bucket;
  final String? _prefix;

  /// Fetches static content from Google Cloud Storage by key.
  ///
  /// Returns content as-is when found, or `null` when not found.
  /// Never throws for "not found" conditions.
  @override
  Future<String?> getByKey(String key) async {
    try {
      final objectName = _prefix != null ? '$_prefix$key' : key;
      final bucket = _storage.bucket(_bucket);

      final bytes = <int>[];
      await for (final chunk in bucket.read(objectName)) {
        bytes.addAll(chunk);
      }

      return String.fromCharCodes(bytes);
    } catch (e, stackTrace) {
      // Log the error for debugging purposes
      ZenLogger.instance.error('Error fetching object from GCS', e, stackTrace);
      return null;
    }
  }
}
