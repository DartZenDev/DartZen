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

## Runtime Guard Pattern for Executor-Only Tasks

Some packages, notably `dartzen_ai`, use **Zone-based runtime guards** to enforce that task code executes only within `ZenExecutor` context. This is a recommended pattern for packages with strict execution requirements.

**Pattern: Zone-Based Guard**

```dart
// In a task's execute() method
@override
Future<TextGenerationResponse> execute() async {
  // Enforce executor-run context
  if (Zone.current['dartzen.executor'] != true) {
    throw StateError(
      'AI tasks MUST be executed via ZenExecutor.execute(), not directly.'
    );
  }
  // ... task implementation
}
```

**When to use**:

- Package operations must never run outside the executor (e.g., AI inference, streaming)
- Package maintains internal service instances that depend on executor lifecycle
- Package cannot tolerate direct invocation outside the execution model

**Zone contract**:

- `Zone.current['dartzen.executor'] == true` — marks code running inside executor
- `Zone.current['dartzen.ai.service']` (example) — executor injects services at runtime
- Task payloads remain pure and serializable; services are injected just-in-time

This pattern is **optional but recommended** for enforcement. It creates a clear, testable boundary: if you try to use the package incorrectly, you get an immediate error.

## Server Transport Boundary

`dartzen_server` imports `dartzen_transport` directly. This is **not a violation**; it is an **architectural responsibility**.

**Why this is correct**:

1. **Server owns the HTTP boundary** — The server package sits at the application perimeter
2. **Transport format negotiation is a server concern** — Selecting JSON vs MessagePack happens at the HTTP layer
3. **Middleware integration requires protocol knowledge** — `zenServerTransportMiddleware()` needs `ZenTransportFormat` and codec types
4. **Not a shortcut** — Server does NOT select executors, route based on environment, or dispatch jobs

**Dependency graph** (correct):

```
HTTP Request
  ↓
dartzen_server (owns boundary)
  ↓ (negotiates format, decodes request)
ZenExecutor (executes task)
  ↓
ZenTransport (internal facade)
  ↓
HTTP Response (encoded via negotiated format)
```

**What server does NOT do**:

- ❌ Select between LocalExecutor vs CloudExecutor
- ❌ Decide whether a task is heavy/medium/light
- ❌ Route based on environment (`dzIsPrd`)
- ❌ Dispatch jobs directly

Server imports transport types only for: format negotiation, codec selection, protocol translation.

## Payments Executor Pattern

`dartzen_payments` uses a custom `Executor` abstraction instead of integrating with `ZenTask`. This is an **intentional architectural divergence**.

**Why**:

1. **Lightweight execution** — Payments are often light-weight operations (< 100ms), not suited for cloud job dispatch
2. **Provider-specific semantics** — Payments need explicit provider selection (Adyen, Strapi, test), which is declarative via `PaymentDescriptor.metadata['provider']`
3. **Retries and idempotency** — Payments have their own retry policy and idempotency windows that differ from the generic job model
4. **Domain coherence** — Payments operations form a cohesive domain unit; wrapping in ZenTask would add nesting without benefit

**Current pattern**:

```dart
// Application wires the executor with providers
final executor = LocalExecutor(
  providers: {'adyen': adyenService, 'strapi': strapiService},
);

// Application calls executor directly
final result = await executor.execute(descriptor, payload);
```

**Trade-off: Single-instance idempotency**:

- Local idempotency cache works for single-instance deployments
- Multi-instance Cloud Run relies on provider-level idempotency (Adyen, Strapi support it natively)
- Document clearly: idempotency is local-only in this implementation

**Future opportunity**:

A `PaymentTask(descriptor, payload)` wrapper could integrate payments with `ZenExecutor` while maintaining the same provider selection and retry semantics. This would unify the execution model across the framework. This is **future work**, not a current requirement.

## Forbidden Patterns in Boundary Packages

These patterns **must not appear** in server, transport, or integration packages:

### ❌ Environment Branching for Routing

**Forbidden**:

```dart
// In server or executor packages
if (dzIsPrd) {
  return await cloudExecutor.execute(task);
} else {
  return await localExecutor.execute(task);
}
```

**Why**: Routing decisions belong in the task descriptor, not in branch logic. Packages should not know about execution environments.

**Correct**: Routing is determined by `ZenTaskDescriptor.weight` (light/medium/heavy), not environment.

### ❌ Direct Jobs Dispatch from Handlers

**Forbidden**:

```dart
// In HTTP handler
final jobId = await zenJobs.enqueue(jobPayload);
response.write(jobId);
```

**Why**: Handlers are HTTP adapters. They call `ZenExecutor.execute(task)`. The executor internally decides whether to dispatch to jobs. Handlers don't know about jobs.

### ❌ Direct Transport Client Usage

**Forbidden**:

```dart
// In application package
final client = ZenClient(transport);
final response = await client.send(request);
```

**Why**: HTTP communication must happen inside `ZenTask.execute()`, not at the application boundary. `ZenClient` is internal to the framework.

### ❌ Executor Selection Logic in Application Code

**Forbidden**:

```dart
// In application layer
final executor = isLight ? LocalExecutor() : CloudExecutor();
await executor.execute(task);
```

**Why**: Executor is injected at startup. Application code calls `zenExecutor.execute(task)` and trusts the routing. Selection logic is centralized, not scattered.

### ✅ What IS Allowed in Server/Boundary Packages

- ✅ HTTP request/response handling (Shelf)
- ✅ Transport format negotiation (JSON/MessagePack selection)
- ✅ Codec integration (ZenEncoder/ZenDecoder)
- ✅ Request/response translation (ZenRequest ↔ HTTP, ZenResult ↔ ZenResponse)
- ✅ Error sanitization for production (hiding internal errors)
- ✅ Middleware composition (explicit pipeline)
- ✅ Configuration validation (environment variables, config file parsing)

## Summary

DartZen execution model is:

- Explicit
- Deterministic
- Event-loop-safe
- Cloud-aware
- Cost-conscious

It exists to ensure that **no single request can silently degrade the entire server**.

This is how DartZen fulfills the promise: **Deterministic Server Execution** without hidden magic, shared state, or accidental blocking.
