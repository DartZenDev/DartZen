# DartZen msgpack

[![pub package](https://img.shields.io/pub/v/dartzen_msgpack.svg)](https://pub.dev/packages/dartzen_msgpack)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Minimal MessagePack implementation for the DartZen ecosystem.**

Zero dependencies. Functional approach. Predictable behavior.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Philosophy

`dartzen_msgpack` follows the Zen Architecture principles:

- **Minimalism**: Only what's needed, nothing more
- **Zero Dependencies**: Pure Dart implementation
- **Predictability**: Stateless functions, no hidden state
- **Functional**: No classes, just pure encode/decode functions

This is NOT a complete MessagePack implementation. It provides only the minimal subset required by `dartzen_transport`.

## 📊 Features

Supports encoding/decoding of:
- `null`
- `bool`
- `int` (up to 64-bit signed/unsigned)
- `double` (64-bit IEEE 754)
- `String` (UTF-8)
- `List`
- `Map<String, dynamic>`
- `Uint8List` (binary data)

## 📦 Installation

```yaml
dependencies:
  dartzen_msgpack:
    path: ../dartzen_msgpack
```

## 🚀 Usage

### Basic Encoding/Decoding

```dart
import 'package:dartzen_msgpack/dartzen_msgpack.dart';

void main() {
  // Encode
  final data = {
    'name': 'Alice',
    'age': 30,
    'active': true,
  };
  final bytes = encode(data);

  // Decode
  final decoded = decode(bytes);
  print(decoded['name']); // Alice
}
```

### Complex Data Structures

```dart
final complex = {
  'users': [
    {'id': 1, 'name': 'Alice'},
    {'id': 2, 'name': 'Bob'},
  ],
  'metadata': {
    'version': '1.0',
    'timestamp': 1234567890,
  },
};

final bytes = encode(complex);
final result = decode(bytes);
```

## ⚙️ API

### `encode(dynamic value) → Uint8List`

Encodes a Dart value to MessagePack binary format.

**Throws**: `ArgumentError` if the value contains unsupported types.

### `decode(Uint8List data) → dynamic`

Decodes MessagePack binary data to a Dart value.

**Throws**: `FormatException` if the data is invalid or corrupted.

## 🛠️ Extending

To add support for additional types:

1. Add encoding logic in `lib/src/msgpack_encoder.dart`
2. Add decoding logic in `lib/src/msgpack_decoder.dart`
3. Update the public API documentation
4. Add tests

Keep it minimal. Only add what's truly needed.

## ⚖️ Comparison with msgpack_dart

| Feature | dartzen_msgpack | msgpack_dart |
|---------|-----------------|--------------|
| Dependencies | 0 | Multiple |
| Size | Minimal | Larger |
| API | Functional | Object-oriented |
| Completeness | Subset | Full spec |
| Philosophy | Zen minimal | Feature complete |

Use `dartzen_msgpack` when you need:
- Zero dependencies
- Minimal bundle size
- Predictable, simple API
- Only basic MessagePack features

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
