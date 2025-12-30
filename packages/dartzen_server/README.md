# DartZen Server

[![pub package](https://img.shields.io/pub/v/dartzen_server.svg)](https://pub.dev/packages/dartzen_server)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The application runtime and orchestration layer for DartZen server applications.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 What This Package Is

`dartzen_server` is the **application boundary** and **runtime entry point** for DartZen server applications running on Google Cloud Platform.

It wires together:

- Domain features (e.g., `dartzen_identity`)
- Infrastructure utilities (`dartzen_firestore`, `dartzen_cache`, `dartzen_storage`)
- Transport layer (`dartzen_transport`)

Its responsibilities are:

- **Process Lifecycle**: Server startup and graceful shutdown
- **Request Routing**: Mapping HTTP paths to handlers
- **Domain Invocation**: Calling domain logic and receiving `ZenResult`
- **Response Translation**: Converting `ZenResult` into HTTP responses via `dartzen_transport`
- **Content Serving**: Providing opaque bytes/strings (content source is `dartzen_storage`)

## 🧘🏻 What This Package Is NOT

`dartzen_server` does **not**:

- Abstract over multiple server runtimes (it is Shelf-native)
- Define or own transport formats (that's `dartzen_transport`)
- Provide multi-cloud abstractions (it is GCP-native)
- Embed storage or caching logic (those are in dedicated packages)
- Auto-wire infrastructure (wiring is explicit)
- Own domain logic or business rules

## 🏗️ Architecture

`dartzen_server` is built on **Shelf** and designed specifically for **Google Cloud Platform** deployment (Cloud Run, Cloud Run Jobs).

### Explicit Wiring

Everything is wired explicitly in code:

- No hidden dependency injection
- No auto-discovery
- No reflection-based behavior
- No magic middleware chains

### Application Boundary

The server is an orchestration layer:

- Domain logic lives in feature packages
- Infrastructure adapters live in utility packages
- The server only connects them

### Responsibility Boundaries

Clear separation of concerns:

- **`dartzen_storage`**: Fetches bytes and content type from GCS
- **`dartzen_server`**: Produces HTTP responses with correct `Content-Type` headers
- **`dartzen_transport`**: Handles API encoding/envelopes (not file serving)

The server does not detect, infer, or override content types—it passes through metadata from storage.

### GCP-Native Design

The runtime aligns with GCP primitives:

- Cloud Run for HTTP services
- Cloud Run Jobs for background tasks
- Firestore for persistence
- Cloud Storage for blobs
- Memorystore for caching

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_server:
    path: ../dartzen_server
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_server: ^latest_version
```

## 🚀 Usage

### Basic Server Application

```dart
import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  final app = ZenServerApplication(
    config: ZenServerConfig(port: 8080),
  );

  await app.run();
}
```

### With Lifecycle Hooks

```dart
import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  final app = ZenServerApplication(
    config: ZenServerConfig(port: 8080),
  );

  // Register startup hook
  app.onStartup(() async {
    print('🚀 Server starting...');
    // Initialize resources (e.g., database connections)
  });

  // Register shutdown hook
  app.onShutdown(() async {
    print('🛑 Server shutting down...');
    // Cleanup resources
  });

  await app.run();
  print('✅ Server listening on http://localhost:8080');
}
```

### Serving Content

`dartzen_server` provides **content routing infrastructure only**—it does not ship any content, routes, or assumptions about what content exists.

All content routing decisions belong to the **application layer**.

```dart
import 'package:dartzen_server/dartzen_server.dart';
import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:gcloud/storage.dart';

void main() async {
  // Configure content provider (where bytes come from)
  final storage = Storage(authClient, project);
  final storageReader = GcsStorageReader(
    storage: storage,
    bucket: 'my-content-bucket',
    prefix: 'static/',
  );

  final contentProvider = StorageContentProvider(
    reader: storageReader,
  );

  final app = ZenServerApplication(
    config: ZenServerConfig(
      port: 8080,
      contentProvider: contentProvider,
      // Application defines what routes exist
      contentRoutes: {
        '/terms': 'legal/terms.html',
        '/privacy': 'legal/privacy.html',
        '/docs/api': 'documentation/api.json',
      },
    ),
  );

  await app.run();
}
```

#### Content Type Handling

Content is served with correct `Content-Type` headers:
- Content type comes from storage metadata (GCS via `dartzen_storage`)
- No detection or inference logic in the server
- Falls back to `application/octet-stream` if unknown

The server is a **pure transport coordinator**—it moves bytes and metadata from storage to HTTP responses without semantic understanding.

#### Key Principles

- **No embedded content**: The server package contains no HTML, JSON, or static files
- **No hardcoded routes**: All HTTP path → content key mappings are defined by the application
- **Opaque content keys**: The server does not interpret keys (they are not file paths)
- **Storage-agnostic interface**: Content can come from GCS, filesystem, memory, or any `ZenContentProvider` implementation
  address: '0.0.0.0',         // Bind address
  port: 8080,                  // Port to listen on
  contentProvider: myProvider, // Optional content provider
);
```

## 🐛 Error Handling

The server follows the `ZenResult` pattern:

1. Domain logic returns `ZenResult<T>`
2. `ZenResponseTranslator` maps `ZenResult` to `ZenResponse`
3. `dartzen_transport` middleware encodes the response

Domain errors are automatically mapped to HTTP status codes:

- `ZenValidationError` → 400
- `ZenUnauthorizedError` → 401
- `ZenNotFoundError` → 404
- `ZenConflictError` → 409
- Other errors → 500

In production, internal error details (500 errors) are hidden from clients.

## 🌐 Localization

`dartzen_server` follows the mandatory DartZen localization pattern.

### Message Layer

All localization keys are encapsulated in `ServerMessages` (`lib/src/l10n/server_messages.dart`).

Direct calls to `ZenLocalizationService.translate` are **forbidden** outside this class.

### Translation File

Translations are stored in `lib/src/l10n/server.en.json`:

```json
{
  "server.health.ok": "Server is healthy",
  "server.error.unknown": "An unexpected server error occurred",
  "server.error.not_found": "Resource not found"
}
```

### Usage

```dart
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_server/dartzen_server.dart';

// 1. Initialize localization service
final localization = ZenLocalizationService(
  config: const ZenLocalizationConfig(),
);

// 2. Load server module translations
await localization.loadModuleMessages(
  'server',
  'en',
  modulePath: 'packages/dartzen_server/lib/src/l10n',
);

// 3. Create message accessor
final messages = ServerMessages(localization, 'en');

// 4. Use localized messages
final healthMessage = messages.healthOk();
final errorMessage = messages.errorNotFound();
```

### Rules

- **Package-scoped**: Each package defines its own messages layer
- **No direct calls**: `ZenLocalizationService.translate` may only be called inside `ServerMessages`
- **Explicit ownership**: The server package owns its localization keys
- **No global managers**: No application-wide message managers allowed

## 📐 Design Philosophy

Following the **Zen Architecture**:

- **Explicit over implicit**: All configuration is visible
- **No hidden global state**: Everything is passed explicitly
- **Deterministic behavior**: Same inputs → same outputs
- **Fail fast in dev/test**: Errors are clear and immediate
- **Safe UX in production**: Generic error messages for internal failures
- **Clear ownership boundaries**: Server orchestrates, doesn't own

## 🧪 Testing

See the `/test` directory for examples:

- `zen_response_translator_test.dart` - Response translation logic
- `server_lifecycle_test.dart` - Startup/shutdown behavior
- `error_mapping_test.dart` - Error code mapping

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
