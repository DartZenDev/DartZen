# dartzen_storage

[![pub package](https://img.shields.io/pub/v/dartzen_storage.svg)](https://pub.dev/packages/dartzen_storage)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Storage reader for Google Cloud Storage and Firebase Storage Emulator.

---

## What is dartzen_storage?

`dartzen_storage` is a **platform-level capability package** that provides a clean, minimal API for reading objects from cloud storage. It is reusable across all DartZen products: servers, background jobs, AI pipelines, and any other Dart application that needs to fetch data from storage.

This package answers **one question only**:

> **"Where do the bytes come from?"**

It provides two implementations:
- **`GcsStorageReader`**: For production Google Cloud Storage
- **`FirebaseStorageReader`**: For Firebase Storage Emulator (development/testing)

## What is dartzen_storage NOT?

`dartzen_storage` is **not**:

- A server package
- An HTTP or Shelf middleware
- A caching layer (use `dartzen_cache` for that)
- A rendering or presentation layer
- A localization system
- A static-content-only abstraction
- A multi-cloud or S3-compatible abstraction

This package is **explicitly GCS-focused**. It does not attempt to support other cloud providers or abstract away cloud-specific details.

---

## Philosophy

`dartzen_storage` follows the **DartZen Zen Architecture**:

- **Explicit over implicit**: All configuration is passed via constructors
- **No hidden global state**: No singletons, no environment variable magic
- **Fail fast in dev/test**: Errors are clear and immediate
- **Safe UX in production**: Returns `null` for missing objects instead of throwing
- **Clear ownership boundaries**: This package owns byte retrieval, nothing more
- **Minimal public API**: Only what you need, nothing you don't

---

## Installation

Add `dartzen_storage` to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_storage:
    path: ../dartzen_storage
```

For published versions:

```yaml
dependencies:
  dartzen_storage: ^0.0.1
```

Then run:

```bash
dart pub get
```

---

## Usage

### Unified Configuration Approach

`dartzen_storage` uses a **unified configuration approach** - the same code works for both production and development (emulator) environments. The package automatically detects the environment using `dzIsPrd` from `dartzen_core`.

```dart
import 'package:dartzen_storage/dartzen_storage.dart';

void main() async {
  // Single configuration for both production and development
  // In production (dzIsPrd = true): uses GCS with ADC
  // In development (dzIsPrd = false): uses Storage Emulator
  final config = GcsStorageConfig(
    projectId: 'your-gcp-project',  // or from GCLOUD_PROJECT env var
    bucket: 'my-content-bucket',
    prefix: 'data/',  // Optional
  );

  // Create storage reader
  // The reader automatically:
  // - Connects to GCS in production
  // - Connects to emulator in development (localhost:9199 by default)
  // - Verifies emulator availability in development
  final reader = GcsStorageReader(config: config);

  // Read an object
  final object = await reader.read('document.json');

  if (object != null) {
    print('Content type: ${object.contentType}');
    print('Size: ${object.size} bytes');
    print('Data: ${object.asString()}');
  } else {
    print('Object not found');
  }
}
```

### Environment Detection

The package uses `dzIsPrd` constant from `dartzen_core` to determine the environment:

- **Production** (`dzIsPrd = true`): Connects to Google Cloud Storage using Application Default Credentials
- **Development** (`dzIsPrd = false`): Connects to Storage Emulator (reads `STORAGE_EMULATOR_HOST` env var or defaults to `localhost:9199`)

### Emulator Configuration

The Storage Emulator is **not optional** - it's a required part of DartZen development workflow. The package performs runtime checks to ensure the emulator is running in development mode.

Emulator host can be configured via:
1. Environment variable: `STORAGE_EMULATOR_HOST=localhost:9199`
2. Default value: `localhost:9199` (standard Firebase Storage Emulator port)

### Usage in Server Context

`dartzen_storage` is designed to be **consumed** by server packages, not to depend on them:

```dart
// In your server setup
import 'package:dartzen_storage/dartzen_storage.dart';

final config = GcsStorageConfig.production(
  projectId: 'my-project',
  bucket: 'my-app-content',
  prefix: 'public/',
);

final storageReader = GcsStorageReader(config: config);

// Pass the reader to your server or caching layer
final server = MyServer(storageReader: storageReader);
```

The server layer can then use the storage reader to fetch content as needed.

---

## API Reference

### `ZenStorageReader`

Abstract interface for reading objects from storage.

```dart
abstract interface class ZenStorageReader {
  Future<StorageObject?> read(String key);
}
```

### `GcsStorageReader`

GCS-backed implementation of `ZenStorageReader`.

```dart
final reader = GcsStorageReader(
  config: GcsStorageConfig(
    projectId: 'my-project',
    bucket: 'my-bucket',
    prefix: 'data/',
  ),
);
```

### `GcsStorageConfig`

Configuration object for connecting to GCS.

- `production` factory: Uses Application Default Credentials (ADC).
- `emulator` factory: Uses anonymous authentication and redirects to emulator host.

### `StorageObject`

Data class representing a storage object:

```dart
class StorageObject {
  final List<int> bytes;
  final String? contentType;
  final int size;

  String asString() => utf8.decode(bytes);
}
```

**Note**: `asString()` assumes UTF-8 encoded text and will throw `FormatException` on binary data (images, PDFs, etc.). Always check `contentType` before calling this method on unknown objects.

---

## Error Handling

`dartzen_storage` follows the **Fail Fast** principle strictly:

### Returns `null` for:
- **404 Not Found**: When the requested object does not exist in the bucket

### Throws exceptions for:
- **403 Permission Denied**: Invalid credentials or insufficient permissions
- **Network errors**: Connection failures, timeouts
- **Misconfiguration**: Wrong bucket name, invalid project ID
- **500+ Server errors**: GCS service failures

This ensures your application **fails immediately** when misconfigured rather than silently returning `null` for all errors. During development and testing, configuration issues surface instantly, making debugging straightforward.

### Example Error Handling

```dart
try {
  final object = await reader.read('document.json');
  if (object == null) {
    // Object doesn't exist - this is a valid domain state
    print('Document not found');
  } else {
    // Process the object
    print(object.asString());
  }
} catch (e) {
  // System error - misconfiguration, network failure, etc.
  // This should be logged and potentially crash the application
  // during development to ensure proper configuration
  print('System error: $e');
  rethrow;
}
```

---

## Limitations

### In-Memory Buffering

`dartzen_storage` buffers entire objects into memory before returning them. Each call to `read()` loads the complete object into memory as a byte array. This means:

- ✅ **Suitable for**: Configuration files, HTML pages, JSON documents, small images
- ❌ **Not suitable for**: Large video files, multi-GB datasets, streaming content

**Guideline**: Use `dartzen_storage` for objects under 10 MB. For larger objects or streaming needs, use the `gcloud` package directly with its streaming APIs.

This limitation is intentional to keep the API minimal and focused on the common use case of reading small to medium-sized configuration and content files.

---

## Reusability

`dartzen_storage` is used across multiple DartZen products:

- **dartzen_server**: Serving static content via HTTP
- **dartzen_cache**: Caching objects for fast retrieval
- **BugEater AI**: Ingesting documentation for semantic search
- **Prudent**: Loading policy documents

Because it has no server or HTTP dependencies, it can be reused anywhere Dart runs.

---

## Stability Guarantees

`dartzen_storage` is in early development (v0.0.1). The API may change between releases until v1.0.0.

Breaking changes will be documented in the [CHANGELOG](CHANGELOG.md).

---

## Contributing

Contributions are welcome! Please read the [Contributing Guide](../../CONTRIBUTING.md) before submitting a pull request.

---

## License

This package is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
