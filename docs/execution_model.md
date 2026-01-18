# Execution Model

## Purpose

This document defines the **execution model** of DartZen servers. It is an **architectural contract**, not a tutorial and not package-level documentation.

Any refactoring of `dartzen_server`, `dartzen_jobs`, or execution-heavy packages **must remain compatible** with this model. New packages and user applications are expected to align with it by default.

The purpose of this model is singular and explicit:

**to guarantee that the main HTTP execution path of the server is never blocked by long-running or CPU-heavy work.**

## Problem Statement

DartZen servers run in an **event-loop-based runtime**.

This means:

- One execution thread handles HTTP requests
- All concurrent requests share that thread
- Blocking one request blocks all others

This is not a theoretical concern and not a language flaw.
It is a mechanical property of Dart (and JavaScript) server runtimes.

Without an explicit execution model:

- Parsing large payloads
- CPU-heavy transformations
- AI / ML calls
- Complex aggregation logic

**DartZen guarantees that long-running or CPU-heavy operations never block the main HTTP execution path.**

## Execution Architecture Overview

DartZen achieves non-blocking execution through **composition**, not magic:

- `ZenExecutor` — central execution router
- `ZenTask` — explicit unit of executable work
- `dartzen_jobs` — durable execution for heavy tasks
- Dart isolates — safe local parallelism when applicable
- GCP Cloud Run — elastic execution boundary

Together, these form a deterministic execution pipeline where **work is routed based on its cost**.

## Task Classification

Every executable operation is classified by expected cost.

### Executor Zone Keys & Service Injection

To support durable, serializable heavy tasks the executor provides a
small, well-known runtime contract via Dart `Zone` values. Heavy task
implementations must not capture runtime-only objects (for example
instances of `AIService` or HTTP clients) inside their payload. Instead,
the executor will inject runtime services when executing a task.

Contract:

- `Zone.current['dartzen.executor'] == true` — marks code running inside the executor.
- `Zone.current['dartzen.ai.service']` — when present it holds the `AIService`
  instance that tasks may use at execution time.

This design ensures that task payloads remain pure and serializable, and
that executor-workers (local isolates or Cloud Run instances) provide the
runtime dependencies just-in-time. Task authors should implement `toPayload()`
and `fromPayload()` for job rehydration and must fetch runtime services from
the Zone (or via executor-provided hooks) when executing.

### Light Tasks

**Characteristics:**

- \< 50–100 ms
- CPU-light
- IO-light
- Deterministic and fast

**Execution:**

- Executed immediately in the main event loop

**Examples:**

- Validation
- Small JSON serialization
- Simple database lookups
- Request routing logic

### Medium Tasks

**Characteristics:**

- Potentially up to \~1 second
- Moderate CPU or IO cost
- Still bounded and predictable

**Execution:**

- Executed in a **local isolate**
- Main event loop remains free

**How Medium is determined:**

- **Static classification**
  Built-in DartZen tasks are pre-classified.
- **Empirical classification**
  First execution is timed; the result is cached and reused for future routing.

Medium tasks are allowed to run locally **only if they are expected to complete quickly**.

### Heavy Tasks

**Characteristics:**

- CPU-intensive
- Large payloads (e.g. multi-MB JSON)
- AI / ML processing
- Unbounded or long-running

**Execution:**

- Routed to `dartzen_jobs`
- Executed asynchronously in Cloud Run
- Detached from the HTTP request lifecycle

**Result:**

- HTTP request stays responsive
- Work is executed safely and durably
- Cost scales only when needed

## ZenExecutor

`ZenExecutor` is the **single entry point for execution decisions**.

Application code does not decide _how_ something runs.
It declares _what_ needs to be done via a **descriptor getter**.

```dart
class ParseJsonTask extends ZenTask<ParseResult> {
  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.medium);
  // ... task definition
}

final result = await zen.execute(ParseJsonTask(payload));
```

The executor decides deterministically and explicitly:

- main event loop (light)
- local isolate with enforced timeout (medium)
- cloud job dispatch via injected dispatcher (heavy)

**Descriptor-first enforcement**:

- Every `ZenTask` MUST implement a `descriptor` getter.
- Missing `descriptor` ⇒ compile-time error (abstract method not implemented).
- Empty descriptor ⇒ hard defaults applied (light, fast, non-retryable).

Heavy tasks produce a fixed, validated job envelope:

```json
{
  "taskType": "TaskClassName",
  "metadata": { "id": "...", "weight": "heavy", "schemaVersion": 1 },
  "payload": { ... }
}
```

Per-call destination overrides for heavy tasks are explicit via
`ExecutionOverrides` (e.g., `queueId`, `serviceUrl`). No implicit fallbacks.

`ZenTask.execute()` is a protected contract; application code calls
`ZenExecutor.execute(task)` only. The executor invokes tasks internally to
honor this boundary while preserving determinism.

## ZenTask and Descriptor

Every `ZenTask<T>` subclass must implement a `descriptor` getter.
The getter is the **ONLY source of truth** for execution cost.

```dart
class ParseJsonTask extends ZenTask<ParseResult> {
  final String payload;
  ParseJsonTask(this.payload);

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
        weight: TaskWeight.medium,
        latency: Latency.slow,
        retryable: true,
      );

  @override
  Future<ParseResult> execute() async {
    // Task business logic
  }

  @override
  Map<String, dynamic> toPayload() => {'payload': payload};
}

// Empty descriptor applies hard defaults (light, fast, non-retryable)
class SimpleTask extends ZenTask<String> {
  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor();

  @override
  Future<String> execute() async => 'done';
}
```

**Note**: The `metadata` property is automatically computed by the base class.
Users never override `metadata` - it's derived from `descriptor` automatically.

### Descriptor semantics

- `weight`: `light` | `medium` | `heavy`. Determines executor routing. **Authoritative and non-negotiable**.
- `latency`: `fast` | `medium` | `slow`. Documents expected duration; used for monitoring/telemetry.
- `retryable`: Indicates whether failures are safe to retry.

### Metadata Derivation

`TaskMetadata` is **automatically computed** by the `ZenTask` base class:

```dart
class MyTask extends ZenTask<int> {
  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
        weight: TaskWeight.medium,
      );

  @override
  Future<int> execute() async => 42;

  // metadata is automatic - never override!
}
```

**Auto-derivation details**:

- `weight`: Taken from `descriptor.weight`
- `id`: Auto-generated from task type name + payload hash
  - Format: `{TaskType}_{hash}` (e.g., `MyTask_123456789`)
  - Deterministic: same task with same payload produces same id
- `schemaVersion`: Always 1

**What Users Write**:

1. `descriptor` getter (REQUIRED - sole source of truth)
2. `execute()` method (REQUIRED - business logic)
3. Optional: `toPayload()` for heavy tasks

**What's Automatic**:

- `metadata` property (computed by base class, never override)
- ID generation (deterministic hash)
- Weight extraction (from descriptor)

**Enforcement contract**:

- `descriptor` getter is REQUIRED (sole source of truth).
- Weight is authoritative (executor enforces routing strictly).
- Metadata is **automatically computed** by base class (users never override it).
- ID generation is automatic (no manual specification).
- Empty descriptor applies hard defaults centrally defined in `DefaultTaskDescriptors`.

## Built-in vs User Tasks

- **DartZen packages**: Tasks declare descriptor getters.
- **User-defined tasks**: Must provide a descriptor getter (source of truth).
- **Metadata is automatic**: Computed by base class; users never override it.

If a user misclassifies task weight in the descriptor, they affect their own server only.
The platform enforces routing based on the descriptor value.

**Enforcement**: Missing `descriptor` getter fails to compile (abstract method).

## Cloud Run Reality

Cloud Run containers may be stopped when idle.

This is acceptable because:

- Heavy tasks are executed via `dartzen_jobs`
- Execution is request-driven
- No background threads are relied upon
- No in-memory state is required for correctness

Isolates are used **only for short-lived, bounded work** ("medium" tasks).
Durable execution ("heavy" tasks) always goes through the job system.

## Determinism and Cost

This model guarantees:

- No hidden blocking
- No implicit concurrency
- No worker folklore
- No background magic

Cost scales only when heavy work exists. Idle servers remain cheap. This is not achieved by scaling harder. It is achieved by **not doing the wrong work in the wrong place**.

## Enforcement

The execution model is enforced through:

- Architecture
- Annotation requirements
- Runtime validation
- Package boundaries
- Explicit APIs

There is no automatic safety net. Violations are design errors.

**Descriptor requirement is non-negotiable**: Every task must declare its execution contract.
Missing descriptor fails immediately with clear error message. This prevents silent misrouting.

If something feels inconvenient to implement under this model,
that discomfort is the signal.

## Summary

DartZen execution model is:

- Explicit
- Deterministic
- Event-loop-safe
- Cloud-aware
- Cost-conscious

It exists to ensure that **no single request can silently degrade the entire server**.

This is how DartZen fulfills the promise: **Deterministic Server Execution** without hidden magic, shared state, or accidental blocking.
