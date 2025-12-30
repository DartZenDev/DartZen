import 'dart:io';

import 'package:dartzen_storage/dartzen_storage.dart';

/// Represents content with its HTTP content type.
class ZenContent {
  /// Creates a [ZenContent].
  const ZenContent({required this.data, required this.contentType});

  /// The content data (string representation).
  final String data;

  /// The HTTP Content-Type header value.
  final String contentType;
}

/// Interface for providing content to the server.
///
/// The server treats content as opaque and relies on the provider to
/// supply both the content data and its correct HTTP content type.
///
/// Implementations determine the content source (filesystem, GCS, memory, etc.).
abstract interface class ZenContentProvider {
  /// Returns content by key, or null if not found.
  ///
  /// The [key] is an opaque identifier with no semantic meaning to the server.
  /// Returns `null` when content is not available for the given key.
  ///
  /// The returned [ZenContent] includes the content type required for
  /// semantically correct HTTP responses.
  Future<ZenContent?> getByKey(String key);
}

/// A [ZenContentProvider] backed by a [ZenStorageReader].
///
/// This provider adapts the `dartzen_storage` reader to the server's
/// content interface. It passes through the content type from GCS metadata.
///
/// Example:
/// ```dart
/// final storageReader = GcsStorageReader(
///   storage: storage,
///   bucket: 'my-bucket',
/// );
///
/// final provider = StorageContentProvider(
///   reader: storageReader,
/// );
/// ```
class StorageContentProvider implements ZenContentProvider {
  /// Creates a [StorageContentProvider].
  ///
  /// The [reader] is used to fetch objects from storage.
  const StorageContentProvider({required ZenStorageReader reader})
    : _reader = reader;

  final ZenStorageReader _reader;

  @override
  Future<ZenContent?> getByKey(String key) async {
    final object = await _reader.read(key);
    if (object == null) return null;

    return ZenContent(
      data: object.asString(),
      contentType: object.contentType ?? 'application/octet-stream',
    );
  }
}

/// A [ZenContentProvider] that reads content from the local filesystem.
///
/// Maps keys to file paths in a directory structure.
/// Content type is inferred from file extension.
///
/// Useful for development and local testing.
class FileContentProvider implements ZenContentProvider {
  /// Creates a [FileContentProvider] with the given [basePath].
  ///
  /// The [basePath] is the root directory where files are located.
  /// Keys are resolved as relative paths from this base.
  const FileContentProvider(this.basePath);

  /// The base path for content files.
  final String basePath;

  @override
  Future<ZenContent?> getByKey(String key) async {
    final file = File('$basePath/$key');
    if (!await file.exists()) {
      return null;
    }
    return ZenContent(
      data: await file.readAsString(),
      contentType: _inferContentType(key),
    );
  }

  String _inferContentType(String filename) {
    if (filename.endsWith('.html')) return 'text/html';
    if (filename.endsWith('.json')) return 'application/json';
    if (filename.endsWith('.xml')) return 'application/xml';
    if (filename.endsWith('.txt')) return 'text/plain';
    if (filename.endsWith('.css')) return 'text/css';
    if (filename.endsWith('.js')) return 'application/javascript';
    if (filename.endsWith('.csv')) return 'text/csv';
    if (filename.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}

/// A [ZenContentProvider] that returns content from an in-memory map.
///
/// Useful for testing or simple deployments where content is injected
/// from environment variables or other sources.
///
/// Supports both uniform content type (via [defaultContentType]) and
/// per-key content types (via [ZenContent] values in map).
class MemoryContentProvider implements ZenContentProvider {
  /// Creates a [MemoryContentProvider] with the given [contentMap].
  ///
  /// The map values can be:
  /// - [String]: Uses [defaultContentType]
  /// - [ZenContent]: Uses the content's own content type
  ///
  /// The [defaultContentType] applies only to String values.
  const MemoryContentProvider(
    this.contentMap, {
    this.defaultContentType = 'text/html',
  });

  /// The map of keys to content.
  /// Values can be String (uses defaultContentType) or ZenContent.
  final Map<String, Object> contentMap;

  /// The default content type for String values.
  final String defaultContentType;

  @override
  Future<ZenContent?> getByKey(String key) async {
    final value = contentMap[key];
    if (value == null) return null;

    if (value is ZenContent) {
      return value;
    }

    if (value is String) {
      return ZenContent(data: value, contentType: defaultContentType);
    }

    throw ArgumentError(
      'Invalid content type: ${value.runtimeType}. '
      'Expected String or ZenContent.',
    );
  }
}
