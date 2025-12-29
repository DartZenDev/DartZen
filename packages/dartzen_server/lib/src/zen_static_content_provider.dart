import 'dart:io';

import 'package:dartzen_storage/dartzen_storage.dart';

/// Interface for providing static content to the server.
///
/// This abstraction ensures that the server does not own or hardcode
/// user-facing content. The server uses keys to identify content
/// without semantic knowledge of what the content represents.
///
/// Providers are data sources only and must not include presentation,
/// localization, or HTTP semantics.
abstract interface class ZenStaticContentProvider {
  /// Returns static content by key, or null if not found.
  ///
  /// The [key] is an opaque identifier with no semantic meaning to the server.
  /// Returns `null` when content is not available for the given key.
  Future<String?> getByKey(String key);
}

/// A [ZenStaticContentProvider] backed by a [ZenStorageReader].
///
/// This provider adapts the platform-level storage reader to the server's
/// static content interface. It converts storage objects to strings.
///
/// Example:
/// ```dart
/// final storageReader = GcsStorageReader(
///   storage: storage,
///   bucket: 'my-bucket',
/// );
///
/// final provider = StorageStaticContentProvider(
///   reader: storageReader,
/// );
/// ```
class StorageStaticContentProvider implements ZenStaticContentProvider {
  /// Creates a [StorageStaticContentProvider].
  ///
  /// The [reader] is used to fetch objects from storage.
  const StorageStaticContentProvider({
    required ZenStorageReader reader,
  }) : _reader = reader;

  final ZenStorageReader _reader;

  @override
  Future<String?> getByKey(String key) async {
    final object = await _reader.read(key);
    return object?.asString();
  }
}

/// A [ZenStaticContentProvider] that reads content from the file system.
///
/// Maps keys to file paths in a directory structure.
class FileStaticContentProvider implements ZenStaticContentProvider {
  /// Creates a [FileStaticContentProvider] with the given [basePath].
  ///
  /// The [basePath] is the root directory where static files are located.
  /// Keys are resolved as relative paths from this base.
  const FileStaticContentProvider(this.basePath);

  /// The base path for static content files.
  final String basePath;

  @override
  Future<String?> getByKey(String key) async {
    final file = File('$basePath/$key.html');
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }
}

/// A [ZenStaticContentProvider] that returns content from a memory map.
///
/// Useful for testing or simple deployments where content is injected
/// from environment variables or other sources.
class MemoryStaticContentProvider implements ZenStaticContentProvider {
  /// Creates a [MemoryStaticContentProvider] with the given [contentMap].
  const MemoryStaticContentProvider(this.contentMap);

  /// The map of keys to HTML content.
  final Map<String, String> contentMap;

  @override
  Future<String?> getByKey(String key) async => contentMap[key];
}
