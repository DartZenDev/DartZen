# DartZen Telemetry

[![pub package](https://img.shields.io/pub/v/dartzen_telemetry.svg)](https://pub.dev/packages/dartzen_telemetry)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Semantic telemetry event tracking for DartZen applications.**

This package provides a small, deterministic, Firestore-first semantic event
layer used by client apps, servers, and background jobs. Events represent
meaningful facts in the system (user journeys, admin actions, analytics) and
are persisted in Firestore as the canonical source of truth.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

- Provide semantic events with a stable schema and naming conventions.
- Persist events to Firestore for Admin Dashboard and analytics.
- Expose a minimal, testable public API for explicit event emission and
  querying.

## 🏗 Architecture & Principles

- Firestore-first: Firestore is the canonical persistent store for telemetry
  events. All runtime Firestore wiring is delegated to `dartzen_firestore`.
- Explicit emission: Events are only recorded when code explicitly emits them.
- Environment-aware: In development the Firestore Emulator is used; in
  production real Firestore is used (both configured via `dartzen_firestore`).
- Minimal public API to keep behavior deterministic and testable.

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_telemetry:
    path: ../dartzen_telemetry
```

### External Usage

```yaml
dependencies:
  dartzen_telemetry:
    version: ^latest_version
```

## 🚀 Usage

The package exports the following public types:

- `TelemetryEvent` — immutable event model
- `TelemetryClient` — public client for emitting and querying events
- `TelemetryStore` — abstract store interface
- `FirestoreTelemetryStore` — Firestore-backed store (default)

Example (Firestore-backed; `dartzen_firestore` handles emulator vs production):

```dart
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

Future<void> main() async {
  // Initialize Firestore via dartzen_firestore (emulator in dev)
  final config = FirestoreConfig(projectId: 'dev-project');
  await FirestoreConnection.initialize(config);

  final store = FirestoreTelemetryStore();
  final client = TelemetryClient(store);

  final event = TelemetryEvent(
    name: 'auth.login.success',
    timestamp: DateTime.now().toUtc(),
    scope: 'identity',
    source: TelemetrySource.client,
    userId: 'user-123',
    sessionId: 'sess-1',
    payload: {'method': 'password'},
  );

  await client.emitEvent(event);

  final results = await client.queryByUserId('user-123');
  print(results);
}
```

## 🔢 Firestore Schema

- Collection: `telemetry_events`

Document fields:

- `id` (string) — document id
- `name` (string) — dot-notation event name
- `timestamp` (timestamp) — UTC timestamp
- `scope` (string)
- `source` (string) — `client|server|job`
- `userId` (string, optional)
- `sessionId` (string, optional)
- `correlationId` (string, optional)
- `payload` (map, optional)

Index suggestions:

- Composite/field indexes supporting queries by `userId`, `sessionId`, and
  `scope`, with ordering by `timestamp` for chronological sequences.

## ❗ Error handling

The package validates event shape at construction time and fails fast for
invalid inputs. Persistence errors are surfaced from the underlying store
implementation (e.g., `dartzen_firestore`), allowing higher-level code to
handle retries or error reporting.

## 🛡️ Stability Guarantees

This package is in early development (0.1.0). Expect breaking changes as the DartZen ecosystem evolves.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
