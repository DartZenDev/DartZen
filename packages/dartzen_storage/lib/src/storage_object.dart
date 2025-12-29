import 'dart:convert';

/// Represents an object retrieved from storage.
///
/// Contains the object's raw bytes and metadata such as content type
/// and size.
///
/// Example:
/// ```dart
/// final object = StorageObject(
///   bytes: utf8.encode('Hello, World!'),
///   contentType: 'text/plain',
/// );
///
/// print(object.size); // 13
/// print(object.asString()); // Hello, World!
/// ```
class StorageObject {
  /// Creates a [StorageObject].
  ///
  /// The [bytes] parameter is the raw object data.
  /// The [contentType] is optional and may be `null` if unknown.
  const StorageObject({required this.bytes, this.contentType});

  /// The raw bytes of the object.
  final List<int> bytes;

  /// The MIME type of the object, if available.
  final String? contentType;

  /// The size of the object in bytes.
  int get size => bytes.length;

  /// Converts the object's bytes to a UTF-8 string.
  ///
  /// **Warning**: This method assumes the bytes represent UTF-8 encoded text.
  /// It will throw [FormatException] if:
  /// - The bytes are not valid UTF-8
  /// - The bytes represent binary data (images, videos, etc.)
  ///
  /// Always check [contentType] before calling this method on unknown data.
  /// For binary data, work with the [bytes] directly.
  String asString() => utf8.decode(bytes);

  @override
  String toString() => 'StorageObject(size: $size, contentType: $contentType)';
}
