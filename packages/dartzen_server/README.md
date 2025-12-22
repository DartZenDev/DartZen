# DartZen Server

[![pub package](https://img.shields.io/pub/v/dartzen_server.svg)](https://pub.dev/packages/dartzen_server)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

The application boundary and orchestration layer for the DartZen ecosystem.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

`dartzen_server` acts as the stage where infrastructure adapters and transport protocols meet the domain. It is an **application boundary**, not a domain owner.

Its primary responsibilities are:

- **Application Lifecycle**: Managing startup and graceful shutdown of the server process.
- **Orchestration**: Coordinating calls between domain use cases and infrastructure adapters (e.g., mapping an HTTP request to a domain call).
- **Transport Translation**: Mapping domain results (`ZenResult`) to transport-agnostic responses (`ZenResponse`) and then to protocol-specific responses (e.g., Shelf `Response`).
- **Static Content**: Serving essential static resources like Terms & Conditions.

## 🧘🏻 Server Philosophy

1.  **Does not own meaning**: It translates signals but does not define business rules.
2.  **Is protocol-agnostic**: While it currently uses Shelf for HTTP, the core orchestration logic is separated from transport concerns.
3.  **Invokes Domain**: It calls domain use cases, passes domain value objects, and receives `ZenResult`.
4.  **Coordinates Infrastructure**: It is the only place where adapter coordination (e.g., Firestore + Cache) is allowed.

## 🏗️ Boundary Rules

- **No Domain Logic**: Business invariants and rules live in the domain packages, never here.
- **No Domain Models**: Domain types are consumed from `dartzen_core` or specific contract packages.
- **Pure Transport**: Handlers should only handle request parsing, domain invocation, and response formatting.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_server:
    path: path/to/dartzen_server
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_server: ^latest_version
```

## 🚀 Usage

```dart
import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  final app = ZenServerApplication(
    config: ZenServerConfig(port: 8080),
  );

  await app.run();
}
```

## 🐛 Error Handling

The server follows the `ZenResult` pattern. Domain failures are captured as `ZenFailure` and translated into `ZenResponse` with appropriate semantic error codes and localizable messages.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
