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

Add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_firestore:
    path: ../dartzen_firestore
```

### External Usage

```yaml
dependencies:
  dartzen_firestore: ^latest_version
```

## 🚀 Usage

### Connection Management

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

// Automatic environment detection
final config = FirestoreConfig.fromEnvironment();
await FirestoreConnection.initialize(config);

// Or explicit configuration
final config = FirestoreConfig.emulator(host: 'localhost', port: 8080);
await FirestoreConnection.initialize(config);

// Access Firestore instance
final firestore = FirestoreConnection.instance;
```

### Type Converters

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

// Timestamp conversion
final timestamp = Timestamp.now();
final zenTimestamp = FirestoreConverters.timestampToZenTimestamp(timestamp);
final backToTimestamp = FirestoreConverters.zenTimestampToTimestamp(zenTimestamp);

// Claims normalization (removes Firestore SDK types)
final rawClaims = {
  'created_at': Timestamp.now(),
  'metadata': {'updated': Timestamp.now()},
};
final normalized = FirestoreConverters.normalizeClaims(rawClaims);
// Result: {'created_at': '2024-01-01T00:00:00.000Z', 'metadata': {'updated': '2024-01-01T00:00:00.000Z'}}
```

### Error Handling

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

try {
  await firestore.collection('users').doc('123').get();
} catch (e, stack) {
  final error = FirestoreErrorMapper.mapException(e, stack);
  // Returns appropriate ZenError (ZenUnauthorizedError, ZenNotFoundError, etc.)
}
```

### Batch Operations

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

final batch = FirestoreBatch(firestore);

batch.set(
  firestore.collection('users').doc('123'),
  {'name': 'Alice', 'age': 30},
);

batch.update(
  firestore.collection('users').doc('456'),
  {'age': 31},
);

batch.delete(firestore.collection('users').doc('789'));

final result = await batch.commit();
result.fold(
  (success) => print('Batch committed successfully'),
  (error) => print('Batch failed: $error'),
);
```

### Transactions

```dart
import 'package:dartzen_firestore/dartzen_firestore.dart';

final result = await FirestoreTransaction.run<int>(
  firestore,
  (transaction) async {
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
);
```

## 🔧 Emulator Configuration

### Environment Variables

Set `FIRESTORE_EMULATOR_HOST` to connect to the Firestore emulator:

```bash
export FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Runtime Check

`dartzen_firestore` performs a runtime check when connecting to the emulator. If the emulator is configured but not running, initialization will fail fast with a clear error message.

## 🐞 Error Handling Philosophy

All Firestore exceptions are mapped to semantic `ZenError` types:

| Firestore Exception | ZenError Type |
|---------------------|---------------|
| `permission-denied` | `ZenUnauthorizedError` |
| `not-found` | `ZenNotFoundError` |
| `already-exists` | `ZenConflictError` |
| `unavailable` | `ZenInfrastructureError` (with error code) |
| `deadline-exceeded` | `ZenInfrastructureError` (timeout) |
| Other | `ZenUnknownError` |

Error messages are localized using `dartzen_localization`.

## 📊 Telemetry (Optional)

Implement the `FirestoreTelemetry` interface to track Firestore operations:

```dart
class MyTelemetry implements FirestoreTelemetry {
  @override
  void onRead(String collection, String? documentId, Duration duration) {
    // Track read operation
  }

  @override
  void onWrite(String collection, String? documentId, Duration duration) {
    // Track write operation
  }

  @override
  void onBatchCommit(int operationCount, Duration duration) {
    // Track batch commit
  }

  @override
  void onTransactionComplete(Duration duration, bool success) {
    // Track transaction
  }

  @override
  void onError(String operation, ZenError error) {
    // Track error
  }
}

// Use with batch/transaction
final batch = FirestoreBatch(firestore, telemetry: MyTelemetry());
```

## 🚫 What This Package Does NOT Do

1. **No domain logic** — No Identity, Payments, or feature-specific code
2. **No repositories** — No repository pattern or data access abstractions
3. **No DTOs** — No domain-to-document mapping
4. **No query builders** — No DSL over Firestore queries
5. **No schema validation** — No runtime schema enforcement
6. **No migrations** — No database migration utilities
7. **No caching** — Use `dartzen_cache` for caching
8. **No authentication** — Use Firebase Auth and `dartzen_identity`
9. **No retries/timeouts** — Handled by Firestore SDK
10. **No multi-database support** — Firestore only

## 🛡️ Stability & Guarantees

* **Version 0.0.1**: Initial release. API may change.
* **Error Handling**: All operations return `ZenResult` with semantic error types.
* **Type Safety**: Strict linting and analysis enabled.
* **Emulator Support**: Automatic detection with runtime validation.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
