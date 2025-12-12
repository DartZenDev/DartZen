import 'dart:typed_data';

import 'src/msgpack_decoder.dart';
import 'src/msgpack_encoder.dart';

/// Encodes a Dart value to MessagePack binary format.
///
/// Supports encoding of:
/// - null
/// - bool
/// - int (up to 64-bit signed/unsigned)
/// - double
/// - String (UTF-8)
/// - List
/// - Map with String keys
///
/// Throws [ArgumentError] if the value contains unsupported types.
///
/// Example:
/// ```dart
/// final data = {'name': 'Alice', 'age': 30};
/// final bytes = encode(data);
/// ```
Uint8List encode(dynamic value) => encodeValue(value);

/// Decodes MessagePack binary data to a Dart value.
///
/// Returns:
/// - `null`
/// - `bool`
/// - `int`
/// - `double`
/// - `String`
/// - `List`
/// - `Map<String, dynamic>`
///
/// Throws [FormatException] if the data is invalid or corrupted.
///
/// Example:
/// ```dart
/// final bytes = encode({'name': 'Alice'});
/// final data = decode(bytes);
/// print(data['name']); // Alice
/// ```
dynamic decode(Uint8List data) => decodeValue(data);
