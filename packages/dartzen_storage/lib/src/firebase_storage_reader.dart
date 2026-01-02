import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'firebase_storage_config.dart';
import 'storage_object.dart';
import 'zen_storage_reader.dart';

/// A [ZenStorageReader] backed by Firebase Storage Emulator.
///
/// This reader fetches objects from Firebase Storage Emulator using the
/// Firebase Storage REST API v0. It is designed for development/testing
/// purposes only and should not be used in production.
///
/// **Important**: This reader only works with Firebase Storage Emulator.
/// For production Google Cloud Storage, use the GCS storage reader instead.
///
/// Example:
/// ```dart
/// final reader = FirebaseStorageReader(
///   config: FirebaseStorageConfig(
///     bucket: 'demo-bucket',
///   ),
/// );
///
/// final object = await reader.read('file.json');
/// ```
class FirebaseStorageReader implements ZenStorageReader {
  /// Creates a [FirebaseStorageReader].
  ///
  /// The [config] defines how to connect to Firebase Storage Emulator.
  ///
  /// For testing purposes, an [httpClient] can be injected directly.
  FirebaseStorageReader({
    required this.config,
    @visibleForTesting http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// The configuration used for this reader.
  final FirebaseStorageConfig config;

  final http.Client _httpClient;

  /// Reads an object from Firebase Storage Emulator by key.
  ///
  /// Returns a [StorageObject] when found, or `null` when not found (404).
  ///
  /// Throws exceptions for:
  /// - Permission errors (403)
  /// - Network failures
  /// - Misconfiguration (wrong bucket, invalid host)
  /// - Any other system errors
  @override
  Future<StorageObject?> read(String key) async {
    try {
      // Apply prefix if configured
      final objectName = config.prefix != null ? '${config.prefix}$key' : key;

      // Encode object name for URL
      final encodedObjectName = Uri.encodeComponent(objectName);

      // Build Firebase Storage Emulator v0 API URL
      // Format: http://host:port/v0/b/{bucket}/o/{object}?alt=media
      final url = Uri.parse(
        'http://${config.emulatorHost}/v0/b/${config.bucket}/o/$encodedObjectName?alt=media',
      );

      ZenLogger.instance.debug(
        'Fetching object from Firebase Storage Emulator: $objectName',
      );

      final response = await _httpClient.get(url);

      if (response.statusCode == 404) {
        ZenLogger.instance.debug('Object not found: $objectName');
        return null;
      }

      if (response.statusCode != 200) {
        throw StorageReadException(
          'Failed to read object from Firebase Storage Emulator: ${response.statusCode} ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      // Get content type from response headers
      final contentType = response.headers['content-type'];

      return StorageObject(bytes: response.bodyBytes, contentType: contentType);
    } catch (e) {
      if (e is StorageReadException) {
        rethrow;
      }

      ZenLogger.instance.error(
        'Error reading from Firebase Storage Emulator',
        error: e,
      );

      throw StorageReadException('Unexpected error reading object: $e');
    }
  }

  /// Closes the HTTP client.
  void close() {
    _httpClient.close();
  }
}

/// Exception thrown when reading from storage fails.
class StorageReadException implements Exception {
  /// Creates a [StorageReadException].
  const StorageReadException(this.message, {this.statusCode});

  /// The error message.
  final String message;

  /// The HTTP status code, if available.
  final int? statusCode;

  @override
  String toString() => 'StorageReadException: $message';
}
