# dartzen_executor

[![pub package](https://img.shields.io/pub/v/dartzen_firestore.svg)](https://pub.dev/packages/dartzen_firestore)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Explicit task execution runtime for DartZen applications.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Overview

`dartzen_executor` provides a deterministic, ownership-driven execution model for tasks of varying computational weight:

- **Light tasks**: Execute inline, non-blocking, in the event loop.
- **Medium tasks**: Execute in a local isolate for bounded CPU work.
- **Heavy tasks**: Dispatch to the jobs system with explicit cloud routing.

## ⚖️ Core Principles

- **Explicit over implicit**: `queueId` and `serviceUrl` are required at construction time.
- **Deterministic routing**: Task weight determines execution path; no hidden magic.
- **Ownership model**: Destination configuration is fixed at executor creation; per-call overrides are explicit and optional.
- **Fixed schema**: Job payloads use a versioned envelope `{taskType, metadata, payload}`.

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_executor:
    path: ../dartzen_executor
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_executor: ^latest_version
```

## 🚀 Usage

```dart
import 'package:dartzen_executor/dartzen_executor.dart';

// 1. Define a task
class ComputePrimeTask extends ZenTask<int> {
  ComputePrimeTask(this.n);

  final int n;

  @override
  TaskMetadata get metadata => TaskMetadata(
    weight: TaskWeight.medium,
    id: 'compute_prime_$n',
  );

  @override
  Future<int> execute() async {
    // CPU-intensive work isolated from event loop
    return _computeNthPrime(n);
  }
}

// 2. Create executor with required config
final executor = ZenExecutor(
  config: ZenExecutorConfig(
    queueId: 'my-task-queue',
    serviceUrl: 'https://my-service.run.app',
  ),
);

// 3. Execute task
final result = await executor.execute(ComputePrimeTask(1000));
result.fold(
  (prime) => print('Result: $prime'),
  (error) => print('Error: ${error.message}'),
);
```

## 📝 Override Policy

Per-call overrides are explicit and optional:

```dart
// Use constructor destination (default)
await executor.execute(heavyTask);

// Explicit per-call override
await executor.execute(
  heavyTask,
  overrides: ExecutionOverrides(
    queueId: 'special-queue',
    serviceUrl: 'https://special-service.run.app',
  ),
);
```

**No implicit fallbacks, env lookups, or magic defaults.**

## ⚙️ Job Schema

Heavy tasks produce a fixed envelope:

```json
{
  "taskType": "MyHeavyTask",
  "metadata": {
    "id": "task-123",
    "weight": "heavy",
    "schemaVersion": 1
  },
  "payload": {
    "param1": "value1",
    "param2": 42
  }
}
```

- `schemaVersion` defaults to `1` and is used only by downstream consumers.
- Executor does not interpret the version field.

## 🏗️ Architecture

- **Light**: Inline async execution in event loop.
- **Medium**: `Isolate.run()` for short-lived, bounded CPU work.
- **Heavy**: Job dispatch via `dartzen_jobs` with explicit configuration.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
