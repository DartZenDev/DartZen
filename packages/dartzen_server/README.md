# DartZen Server

[![pub package](https://img.shields.io/pub/v/dartzen_server.svg)](https://pub.dev/packages/dartzen_server)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The application runtime and orchestration layer for DartZen server applications.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 What This Package Is

`dartzen_server` is the **application boundary** and **runtime entry point** for DartZen server applications running on Google Cloud Platform.

It is an **execution orchestrator**, not an execution engine.

The server runtime:

- Hosts HTTP endpoints
- Wires infrastructure and domain features
- Delegates execution safely within a single event-loop runtime

It wires together:

- Domain features (e.g. `dartzen_identity`)
- Infrastructure utilities (`dartzen_firestore`, `dartzen_cache`, `dartzen_storage`)
- Transport layer (`dartzen_transport`)

Its responsibilities are strictly limited to:

- **Process Lifecycle**: Startup and graceful shutdown
- **Request Routing**: Mapping HTTP paths to handlers
- **Execution Delegation**: Invoking domain logic in a non-blocking manner
- **Response Translation**: Converting `ZenResult` into HTTP responses
- **Content Serving**: Streaming opaque bytes and metadata from storage

## 🧘🏻 What This Package Is NOT

`dartzen_server` does **not**:

- Execute CPU-heavy or blocking logic
- Abstract over multiple server runtimes
- Own domain or business logic
- Perform synchronous I/O
- Hide execution behavior behind magic abstractions
- Act as a background worker system

If something blocks the event loop, it does not belong here.

## ⚙️ Execution Model

DartZen servers operate in a **single event-loop runtime**.

This has hard architectural consequences.

- All HTTP requests share one execution thread
- Blocking one request blocks all requests
- Synchronous CPU work is a runtime defect

Because of this:

- The server **never assumes domain logic is safe to run inline**
- Long-running or CPU-heavy work must be delegated
- Non-blocking execution is a correctness requirement, not an optimization

This package follows the DartZen execution model defined in:

**`/docs/execution-model.md`**

Any refactoring or extension of `dartzen_server` must remain compatible with that document.

## 🏗️ Architecture

`dartzen_server` is built on **Shelf** and designed specifically for **Google Cloud Platform** deployment (Cloud Run, Cloud Run Jobs).

Shelf is used as a **minimal HTTP kernel**, not as a framework.

### Explicit Wiring

Everything is wired explicitly in code:

- No hidden dependency injection
- No auto-discovery
- No reflection-based behavior
- No implicit middleware chains

If something happens, it happens because it is written.

### Application Boundary

The server is an **orchestration layer**, not a domain container.

- Domain logic lives in feature packages
- Infrastructure adapters live in utility packages
- The server coordinates and delegates execution

The server does **not** own execution strategy. It enforces execution safety.

### Responsibility Boundaries

Clear separation of concerns:

- **`dartzen_storage`**: Fetches bytes and content metadata
- **`dartzen_server`**: Streams bytes into HTTP responses
- **`dartzen_transport`**: Encodes API responses and envelopes

The server does not infer, detect, or reinterpret content. It passes through bytes and metadata verbatim.

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

### Execution Safety Notice

All request handlers **must be non-blocking**.

- No synchronous I/O
- No CPU-heavy computation
- No blocking waits

Violating these rules blocks the entire server.

### With Lifecycle Hooks

```dart
import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  final app = ZenServerApplication(
    config: ZenServerConfig(port: 8080),
  );

  // Register startup hook
  app.onStartup(() async {
    // Initialize async resources only
  });

  // Register shutdown hook
  app.onShutdown(() async {
    // Cleanup resources
  });

  await app.run();
}
```

Lifecycle hooks follow the same execution constraints as request handlers.

### Serving Content

`dartzen_server` provides **content routing infrastructure only** — it does not ship any content, routes, or assumptions about what content exists.

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

The server is a **pure transport coordinator** — it moves bytes and metadata from storage to HTTP responses without semantic understanding.

#### Key Principles

- **No embedded content**: The server package contains no HTML, JSON, or static files
- **No hardcoded routes**: All HTTP path → content key mappings are defined by the application
- **Opaque content keys**: The server does not interpret keys (they are not file paths)
- **Storage-agnostic interface**: Content can come from GCS, filesystem, memory, or any `ZenContentProvider` implementation

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
