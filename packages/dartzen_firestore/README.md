# DartZen Firestore

[![pub package](https://img.shields.io/pub/v/dartzen_firestore.svg)](https://pub.dev/packages/dartzen_firestore)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Firestore utility toolkit for DartZen packages.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

`dartzen_firestore` provides low-level Firestore utilities for the DartZen ecosystem:

* Connection management (production vs emulator)
* Type converters (Timestamp ↔ ZenTimestamp, claims normalization)
* Batch and transaction helpers with `ZenResult` support
* Error normalization (Firestore exceptions → `ZenError`)
* Optional telemetry hooks
* Emulator support with runtime availability checks

**This package is domain-agnostic.** It does NOT contain:
* Domain logic (Identity, Payments, etc.)
* Repository patterns or data access abstractions
* DTOs or domain-to-document mapping
* Query builders or schema validation

## 🏗 Architecture

`dartzen_firestore` follows **Zen Architecture** principles:

* **Explicit over implicit** — No hidden configuration or magic
* **Utilities over abstractions** — Small, focused helpers instead of complex frameworks
* **GCP-native** — Built specifically for Google Cloud Firestore
* **Fail fast** — Clear errors in development, graceful degradation in production

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_firestore:
    path: ../dartzen_firestore
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_firestore: ^latest_version
```

## 🚀 Usage

### Unified Configuration Approach

`dartzen_firestore` uses a **unified configuration approach** - the same initialization code works for both production and development (emulator) environments.

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

// Single configuration for both production and development
// In production (dzIsPrd = true): connects to Firestore
// In development (dzIsPrd = false): connects to Firestore Emulator
final config = FirestoreConfig(projectId: 'my-project');

// Initialize connection
// The package automatically:
// - Connects to Firestore in production
// - Connects to emulator in development (reads FIRESTORE_EMULATOR_HOST)
// - Verifies emulator availability in development
await FirestoreConnection.initialize(config);

// Access Firestore instance
final firestore = FirestoreConnection.client;
```

### Environment Detection

The package uses `dzIsPrd` constant from `dartzen_core` to determine the environment:

- **Production** (`dzIsPrd = true`): Connects to Google Cloud Firestore
- **Development** (`dzIsPrd = false`): Connects to Firestore Emulator (reads `FIRESTORE_EMULATOR_HOST` env var or defaults to `localhost:8080`)

### Emulator Configuration

The Firestore Emulator is **not optional** - it's a required part of DartZen development workflow. The package performs runtime checks to ensure the emulator is running in development mode.

Emulator host can be configured via:
1. Environment variable: `FIRESTORE_EMULATOR_HOST=localhost:8080`
2. Default value: `localhost:8080` (standard Firebase Firestore Emulator port)

### Batch Operations

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

// Initialize batch with localization
final batch = FirestoreBatch(firestore, localization: localization);

batch.set(
  firestore.collection('users').doc('123'),
  {'name': 'Alice', 'age': 30},
);

batch.update(
  firestore.collection('users').doc('456'),
  {'age': 31},
);

batch.delete(firestore.collection('users').doc('789'));

// Commit with optional telemetry metadata
final result = await batch.commit(metadata: {'targetModule': 'catalog'});

result.fold(
  (_) => print('Batch committed successfully'),
  (error) => print('Batch failed: $error'),
);
```

### Transactions

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

final result = await FirestoreTransaction.run<int>(
  firestore,
  (Transaction transaction) async {
    final docRef = firestore.collection('counters').doc('global');
    final snapshot = await transaction.get(docRef);

    if (!snapshot.exists) {
      return const ZenResult.err(ZenNotFoundError('Counter not found'));
    }

    final currentValue = snapshot.data()?['value'] as int? ?? 0;
    final newValue = currentValue + 1;

    transaction.update(docRef, {'value': newValue});
    return ZenResult.ok(newValue);
  },
  localization: localization,
  metadata: {'operation': 'increment_counter'},
);
```

## 🐞 Error Handling Philosophy

All Firestore exceptions are mapped to semantic `ZenError` types:

| Firestore Exception | ZenError Type |
|---------------------|---------------|
| `permission-denied` | `ZenUnauthorizedError` |
| `not-found` | `ZenNotFoundError` |
| `already-exists` | `ZenConflictError` |
| `unavailable` | `ZenUnknownError` (with error code) |
| `deadline-exceeded` | `ZenUnknownError` (timeout) |
| Other | `ZenUnknownError` |

Error messages are localized using `dartzen_localization`.

## 📊 Telemetry

Implement the `FirestoreTelemetry` interface to track Firestore operations with metadata support:

```dart
class MyTelemetry implements FirestoreTelemetry {
  @override
  void onRead(String path, Duration latency, {Map<String, dynamic>? metadata}) {
    // Track read
  }

  @override
  void onBatchCommit(int count, Duration latency, {Map<String, dynamic>? metadata}) {
    // Track batch
  }

  @override
  void onError(String op, ZenError error, {Map<String, dynamic>? metadata}) {
    // Track error
  }

  // ... other hooks
}
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
