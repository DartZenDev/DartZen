# dartzen_executor

[![pub package](https://img.shields.io/pub/v/dartzen_executor.svg)](https://pub.dev/packages/dartzen_executor)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Explicit task execution runtime for DartZen applications.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Overview

`dartzen_executor` provides a deterministic, descriptor-first execution model for tasks of varying computational weight:

- **Light tasks**: Execute inline, non-blocking, in the event loop.
- **Medium tasks**: Execute in a local isolate for bounded CPU work.
- **Heavy tasks**: Dispatch to the jobs system with explicit cloud routing.

## ⚖️ Core Principles

- **Descriptor-only**: Every task must implement a `descriptor` getter (sole source of truth).
- **Hard defaults**: Empty descriptor applies strict defaults (light, fast, non-retryable).
- **Explicit over implicit**: `queueId` and `serviceUrl` are required at construction time.
- **Deterministic routing**: Task weight determines execution path; no hidden magic.
- **Ownership model**: Destination configuration is fixed at executor creation; per-call overrides are explicit and optional.
- **Fixed schema**: Job payloads use a versioned envelope `{taskType, metadata, payload}`.

## 🔐 Descriptor-only Contract

- Implement a `descriptor` getter that returns `const ZenTaskDescriptor(...)`.
- `descriptor` is the sole source of truth for execution cost and behavior.
- `metadata` is auto-derived by the base class and marked non-virtual; do not override.
- Defaults apply when the descriptor is empty (light, fast, non-retryable).
- Routing is strictly enforced by `weight` (light/medium/heavy).

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

### 1. Define a Task with Descriptor

Every task MUST provide a `descriptor` getter. Metadata is computed automatically by the base class.

```dart
import 'package:dartzen_executor/dartzen_executor.dart';

// Explicit descriptor
class ComputePrimeTask extends ZenTask<int> {
  ComputePrimeTask(this.n);

  final int n;

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.medium,
    latency: Latency.slow,
    retryable: true,
  );

  @override
  Future<int> execute() async {
    // CPU-intensive work isolated from event loop
    return _computeNthPrime(n);
  }
}

// Empty descriptor applies hard defaults (light, fast, non-retryable)
class SimpleTask extends ZenTask<String> {
  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor();

  @override
  Future<String> execute() async => 'done';
}
```

### 2. Create Executor with Required Config

```dart
final executor = ZenExecutor(
  config: ZenExecutorConfig(
    queueId: 'my-task-queue',
    serviceUrl: 'https://my-service.run.app',
  ),
  dispatcher: MyJobDispatcher(),
);
```

### 3. Execute Task

```dart
final result = await executor.execute(ComputePrimeTask(1000));
result.fold(
  (prime) => print('Result: $prime'),
  (error) => print('Error: ${error.message}'),
);
```

## 🏷️ Descriptor Semantics

### Contract

```dart
class MyTask extends ZenTask<T> {
  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor();
}
```

- **Weight**: Routing weight (`light` | `medium` | `heavy`). Defaults: `light`.
- **Latency**: Expected duration (`fast` | `medium` | `slow`). Defaults: `fast`.
- **Retryable**: Safe to retry on failure. Defaults: `false`.

**Empty descriptor** applies hard defaults. This ensures lightweight tasks don't accidentally become expensive.

### Examples

```dart
// Explicit
class Task1 extends ZenTask<T> {
  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.light,
    latency: Latency.fast,
    retryable: false,
  );
}

// Defaults (same as above)
class Task2 extends ZenTask<T> {
  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor();
}
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

## 🔍 Enforcement

- **Descriptor is mandatory**: Missing `descriptor` getter fails at compile time.
- **Defaults are hard-coded**: No implicit inference or smart detection.
- **Weight is absolute**: Task weight enforces routing; no fallback.
- **Medium timeout is hard failure**: Exceeding timeout indicates misclassification, not transience.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
