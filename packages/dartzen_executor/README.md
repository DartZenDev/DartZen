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

## 🛡️ Runtime Guard (Zone)

`ZenExecutor.execute()` runs tasks inside a Zone with `#dartzenExecutor` marker.

**This is an opt-in validation mechanism, not mandatory enforcement.**

- The executor automatically marks its execution context via Zone.
- Tasks can override `validateExecutorContext()` to enforce executor-only invocation.
- By default, tasks trust the executor's public API design for routing.

### Default Behavior (No Guard)

Most tasks don't need explicit validation:

```dart
class MyTask extends ZenTask<String> {
  @override
  TaskDescriptor get descriptor => TaskDescriptor(
    taskType: 'MyTask',
    weight: TaskWeight.light,
  );

  @override
  Future<String> execute() async => 'result';
  // No validateExecutorContext override = no zone check
}

// ✅ This works normally
final result = await executor.execute(myTask);
```

### Opt-In Guard (For Strict Isolation)

Tasks requiring service injection or strict context control can enforce validation:

```dart
class SecureAiTask extends ZenTask<String> {
  @override
  TaskDescriptor get descriptor => TaskDescriptor(
    taskType: 'SecureAiTask',
    weight: TaskWeight.heavy,
  );

  @override
  void validateExecutorContext() {
    if (Zone.current[#dartzenExecutor] != true) {
      throw StateError('SecureAiTask requires executor context');
    }
  }

  @override
  Future<String> execute() async => 'AI result with services';
}
```

**Architecture Note:** The zone marker enables future extensions like distributed
tracing, service injection, and observability hooks. Most tasks rely on the
executor's public API design for routing enforcement.

Zone values can also carry runtime services (e.g., AI clients) injected by the executor or server workers, avoiding non-serializable captures in payloads.

## ⚙️ Heavy Task Configuration Invariant

**CRITICAL REQUIREMENT:** `ZenExecutor` config (`queueId`, `serviceUrl`) **MUST**
match the `ZenJobs.instance` configuration at runtime.

### Why This Matters

`ZenJobs` is initialized once at app startup with queue/service configuration.
The executor's config parameters **document the intended destination** but are
**NOT enforced** at dispatch time (no runtime validation).

**Violating this invariant** (executor config ≠ ZenJobs config) causes jobs to
route to the wrong queue/service, visible only in production.

### Enforcement Strategy

**Current approach:** Document invariant + fail-fast at integration test level.

```dart
// ✅ CORRECT: Executor config matches ZenJobs init
await ZenJobs.instance.init(
  queueId: 'my-queue',
  serviceUrl: 'https://worker.run.app',
);

final executor = ZenExecutor(
  config: ZenExecutorConfig(
    queueId: 'my-queue',  // MUST match ZenJobs
    serviceUrl: 'https://worker.run.app',  // MUST match ZenJobs
  ),
  dispatcher: const CloudJobDispatcher(),
);

// ❌ WRONG: Mismatched config (silent production failure)
await ZenJobs.instance.init(
  queueId: 'queue-a',
  serviceUrl: 'https://worker-a.run.app',
);

final executor = ZenExecutor(
  config: ZenExecutorConfig(
    queueId: 'queue-b',  // ⚠️ Mismatch! Jobs go to queue-a, not queue-b
    serviceUrl: 'https://worker-b.run.app',
  ),
  dispatcher: const CloudJobDispatcher(),
);
```

### Future Enhancement Options

1. **Runtime validation:** Add `ZenJobs.getConfig()` API + assert match in dispatcher
2. **Per-call routing:** Enhance `ZenJobs.trigger(queue, service, ...)` to accept destination

## 🔄 Heavy Task Rehydration (Minimal Contract)

Heavy tasks are serialized to `JobEnvelope` and dispatched to Cloud Tasks.
Job workers receive the envelope, rehydrate the task, and execute it.

**⚠️ CRITICAL: `fromPayload()` must be pure.**

- No side effects
- No network calls or database access
- No async operations
- Only reconstruct state from JSON

Violating this causes unpredictable failures in job workers.

### Recommended Pattern

1. Add a static `fromPayload(Map<String,dynamic>)` on the task class
2. Register it in `TaskFactoryRegistry` at worker startup
3. Use the internal `rehydrateAndExecute()` helper in your Cloud Run handler

```dart
import 'package:dartzen_executor/src/models/task.dart';
import 'package:dartzen_executor/src/models/task_rehydration.dart';
import 'package:dartzen_executor/src/models/task_worker.dart';
import 'package:dartzen_executor/src/models/job_envelope.dart';

// 1. Define heavy task with pure fromPayload
class DataProcessingTask extends ZenTask<Map<String, dynamic>> {
  DataProcessingTask({required this.data});
  final List<int> data;

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.heavy,
  );

  @override
  Future<Map<String, dynamic>> execute() async {
    final sum = data.reduce((a, b) => a + b);
    return {
      'count': data.length,
      'sum': sum,
      'average': sum / data.length,
    };
  }

  @override
  Map<String, dynamic> toPayload() => {'data': data};

  // ✅ Pure factory: no side effects, no async
  static ZenTask<Map<String, dynamic>> fromPayload(Map<String, dynamic> json) =>
      DataProcessingTask(data: List<int>.from(json['data'] as List));
}

// 2. Register factory at worker startup
void initWorker() {
  TaskFactoryRegistry.register<Map<String, dynamic>>(
    'DataProcessingTask',
    DataProcessingTask.fromPayload,
  );
}

// 3. Use worker helper in Cloud Run handler
@CloudFunction()
Future<Response> handleHeavyTask(Request request) async {
  final json = await request.readAsString();
  final envelope = JobEnvelope.fromJson(jsonDecode(json));

  // Internal helper: rehydrate + execute
  final result = await rehydrateAndExecute(envelope);

  return result.fold(
    (value) => Response.ok(jsonEncode(value)),
    (error) => Response.internalServerError(body: error.message),
  );
}
```

### End-to-End Flow

1. **Executor side:** Task → `JobEnvelope.fromTask()` → JSON → Cloud Tasks
2. **Transport:** HTTP request body contains serialized envelope
3. **Worker side:** JSON → `JobEnvelope.fromJson()` → `rehydrateAndExecute()` → Result

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
