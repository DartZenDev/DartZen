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

can silently block the event loop and degrade the entire server under load.

## Core Guarantee

**DartZen guarantees that long-running or CPU-heavy operations never block the main HTTP execution path.**

This is achieved by **explicit task classification and execution routing**, not by wishful async/await usage.

HTTP transport is treated as a **coordination layer**, not a place where heavy work happens.

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
It declares _what_ needs to be done.

```dart
final result = await zen.execute(
  ParseJsonTask(payload),
);
```

The executor decides deterministically and explicitly:

- main event loop (light)
- local isolate with enforced timeout (medium)
- cloud job dispatch via injected dispatcher (heavy)

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

## ZenTask and Descriptor Annotation

Custom tasks are defined as `ZenTask<T>` and may declare a **descriptor
annotation** for clarity and documentation.

```dart
@ZenTaskDescriptor(
  weight: TaskWeight.medium,
  latency: Latency.slow,
  retryable: true,
)
class ParseJsonTask extends ZenTask<ParseResult> {
  final String payload;
  ParseJsonTask(this.payload);

  @override
  TaskMetadata get metadata => TaskMetadata(
    weight: TaskWeight.medium,
    id: 'parse_json_${payload.hashCode}',
  );

  @override
  Future<ParseResult> execute() async {
    // Task business logic
  }

  @override
  Map<String, dynamic> toPayload() => {'payload': payload};
}
```

### Descriptor semantics

- `weight`: `light` | `medium` | `heavy`. Determines execution routing.
- `latency`: `fast` | `medium` | `slow`. Used for monitoring and documentation.
- `retryable`: Indicates whether failures are safe to retry.

The descriptor is for documentation and tooling; the **authoritative routing
contract** is the `TaskMetadata` returned by the task.

## Built-in vs User Tasks

- **DartZen packages**: Tasks are pre-classified and safe by default.
- **User-defined tasks**: The platform provides tools; responsibility is explicit.

This is intentional.

If a user lies about task cost, they can break their own server. They cannot silently break the platform.

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
- Package boundaries
- Explicit APIs

There is no automatic safety net. Violations are design errors.

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
