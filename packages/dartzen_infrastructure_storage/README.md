# DartZen Infrastructure Storage

[![pub package](https://img.shields.io/pub/v/dartzen_infrastructure_storage.svg)](https://pub.dev/packages/dartzen_infrastructure_storage)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Storage-backed static content providers for the DartZen ecosystem.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

`dartzen_infrastructure_storage` is a **pure infrastructure package** that provides external storage implementations of `ZenStaticContentProvider` from `dartzen_server`.

This package implements storage-backed providers only. It does **not** introduce defaults, fallbacks, or implicit wiring. All configuration is explicit and happens at the application level.

## 🏗️ What This Package Provides

- **GCS-backed Provider**: Fetches static content from Google Cloud Storage
- **Explicit Configuration**: No environment inference or default buckets
- **Clean Abstraction**: Returns raw content or `null` — no HTML generation, no error messages

## 🚫 What This Package Does NOT Do

- Register itself anywhere
- Auto-configure anything
- Introduce default providers
- Change server behavior implicitly
- Read from local filesystem
- Embed HTML or user-facing strings
- Provide fallback content
- Hardcode bucket names

## 🧘 Architecture

This package answers only one question:

**"Where do the bytes come from?"**

All other concerns (HTTP, localization, HTML structure, error presentation) remain outside its scope.

The server does **not** assume or select a static content source. Usage requires explicit wiring via `ZenServerConfig`.

## 📦 Installation

### In a Melos Workspace

Add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_storage:
    path: ../dartzen_infrastructure_storage
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_infrastructure_storage: ^latest_version
```

## 🚀 Usage

### GCS-backed Provider

Configure and wire the provider explicitly:

```dart
import 'package:dartzen_infrastructure_storage/dartzen_infrastructure_storage.dart';
import 'package:dartzen_server/dartzen_server.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

void main() async {
  // 1. Configure GCS client
  final authClient = await auth.clientViaApplicationDefaultCredentials(
    scopes: [storage.StorageApi.devstorageReadOnlyScope],
  );
  final storage = Storage(authClient, 'your-project-id');

  // 2. Create provider with explicit configuration
  final provider = GcsStaticContentProvider(
    storage: storage,
    bucket: 'my-static-content',
    prefix: 'public/', // Optional
  );

  // 3. Wire into server configuration
  final config = ZenServerConfig(
    port: 8080,
    staticContentProvider: provider,
  );

  // 4. Start server
  final app = ZenServerApplication(config: config);
  await app.run();
}
```

### Provider Contract

`GcsStaticContentProvider` implements `ZenStaticContentProvider`:

**Method**: `Future<String?> getByKey(String key)`

**Behavior**:

- Returns content as-is when found
- Returns `null` when not found
- **Never throws** for "not found" conditions
- Does **not** return fallback HTML or error messages

### Configuration

The provider requires explicit configuration:

- **`storage`** (required): Configured `Storage` client
- **`bucket`** (required): GCS bucket name
- **`prefix`** (optional): Object key prefix (e.g., `'public/'`)

**No defaults. No environment inference. No implicit credentials logic beyond SDK defaults.**

## ⚙️ API

### `GcsStaticContentProvider`

GCS-backed implementation of `ZenStaticContentProvider`.

**Constructor**:

```dart
GcsStaticContentProvider({
  required Storage storage,
  required String bucket,
  String? prefix,
})
```

**Method**:

```dart
Future<String?> getByKey(String key)
```

## 🔄 Replacing This Provider

You can replace this provider with any other implementation of `ZenStaticContentProvider` without affecting:

- Localization behavior
- HTTP behavior
- Server routing
- Error handling

The provider is a **pure data source** with no knowledge of how its content is used.

## 📊 Example

See [`example/main.dart`](example/main.dart) for a complete working example.

## 🧪 Testing

The package includes comprehensive unit tests demonstrating:

- Content retrieval when object exists
- `null` return when object does not exist
- Prefix application
- Multi-chunk stream handling
- Error handling (returns `null` on any error)

Run tests:

```bash
dart test
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
