# DartZen Jobs

[![pub package](https://img.shields.io/pub/v/dartzen_jobs.svg)](https://pub.dev/packages/dartzen_jobs)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Deterministic background execution for serverless Dart.**

A unified background and scheduled jobs system for DartZen applications, designed for Cloud Run without blocking, surprises, or hidden concurrency.

> IMPORTANT: `dartzen_jobs` is a low-level runtime/registry package and is
> not intended for direct use by application code. Do not call job handlers,
> runtime adapters, or executor internals directly from your application.
> Instead, use the single public entry point `ZenJobsExecutor` with an
> explicit mode (`development` or `production`). Internal executors remain
> under `src/internal` for framework and test use only.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

`dartzen_jobs` is a **deterministic job runtime** that provides a robust, Zen-compliant framework for executing background tasks in a serverless environment (Cloud Run):

- **Endpoint Jobs**: Event-driven jobs triggered asynchronously via Cloud Tasks.
- **Scheduled Jobs**: Cron-based jobs triggered by Cloud Scheduler.
- **Periodic Jobs**: Interval-based jobs (e.g., "every 5 minutes") triggered efficiently via an internal "Master Job" to reduce Cloud Run container starts and costs.
- **Local Simulation**: Fully functional simulation mode for local development without needing real GCP infrastructure.

It is not a queue wrapper and not a cron helper. It defines **how and when work executes**, with explicit guarantees about:

- execution order
- retries
- cost
- and CPU safety

## 💣 Why this package exists

Serverless job execution usually fails in predictable ways:

- jobs block the event loop
- CPU-heavy tasks freeze the container
- retries are implicit and non-deterministic
- schedules require redeploys
- cost explodes silently

`dartzen_jobs` exists to **make background work explicit and controllable**.

## 🧠 Core guarantees

- **Deterministic execution**: A job runs because and only because a trigger exists.
- **Non-blocking by design**: Jobs must not block the server event loop.
- **CPU-intensive work is explicit**: Heavy computation is isolated, never accidental.
- **Retry behavior is visible**: No implicit retries hidden in infrastructure.
- **Cost-aware scheduling**: Fewer container starts, fewer surprises.

## 🏗 Architecture

`dartzen_jobs` is built on **Zen Architecture** principles:

- **GCP-Native**: Designed specifically for Cloud Tasks and Cloud Scheduler.
- **Stateful Configuration**: Job configurations (enabled status, schedules, dependencies) are stored in Firestore, allowing runtime control without redeployment.
- **Cost-Aware**: The "Master Job" pattern batches periodic job checks to minimize execution time and billable invocations.
- **Telemetry Integration**: Automatically emits detailed telemetry events (`start`, `success`, `failure`) for all jobs.

## ⚙️ Execution model (important)

### Event-loop safety

Jobs run inside a Cloud Run container and **must not block** the Dart event loop.

Allowed:

- async I/O
- network calls
- database operations

Not allowed:

- long synchronous loops
- heavy CPU-bound computation
- blocking waits

### CPU-intensive jobs

CPU-heavy work must be handled explicitly by one of these strategies:

- isolate-based execution
- external worker services
- batch processing outside request handlers

`dartzen_jobs` makes CPU-heavy work **a conscious architectural choice**, not an accident.

## 🔐 Descriptor-only Contract (interop)

When `dartzen_executor` dispatches heavy tasks to `dartzen_jobs`, tasks declare a
`descriptor` getter (not annotations). The descriptor is the sole source of truth
for routing (`light`/`medium`/`heavy`) and behavior, while `metadata` is auto-derived.
This keeps job envelopes deterministic and verifiable.

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_jobs:
    path: ../dartzen_jobs
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_jobs: ^latest_version
```

## 🚀 Usage

### 1. Initialization (Registry-only)

Architecture notes:

- Direct execution is forbidden: runtime job execution, retries, scheduling, persistence, and adapter invocation are the sole responsibility of an `Executor` implementation. Do not call job handlers, dispatchers, or cloud adapters directly from your application code.
- Executor-only architecture: `ZenJobs` is a descriptor registry only. To run jobs, use a pluggable `Executor` (local/cloud/test) which owns lifecycle, error classification, retry/backoff, scheduling semantics, and persistence.
- Smart Detection / Auto Descriptor inference: NOT implemented. This feature is intentionally deferred to avoid accidental side-effects and is planned for a future release.

First, create the registry and register `JobDescriptor`s. Handlers are registered separately via `HandlerRegistry`.

```dart
import 'package:dartzen_jobs/dartzen_jobs.dart';

void main() async {
  // Registry-only: no runtime dependencies are provided here.
  ZenJobs.instance = ZenJobs();

  // Register descriptors (metadata only).
  ZenJobs.instance.register(
    JobDescriptor(id: 'send_welcome_email', type: JobType.endpoint),
  );

  // Register handlers separately.
  HandlerRegistry.register('send_welcome_email', (ctx) async {
    final userId = ctx.payload?['userId'];
    print('Sending welcome email to $userId');
  });

  // Create and start a runtime executor explicitly.
  final jobs = ZenJobsExecutor.development();
  await jobs.start();
}
```

### 2. Defining Jobs

Create `JobDescriptor`s to define your jobs:

```dart
final myEmail = JobDescriptor(
  id: 'send_welcome_email',
  type: JobType.endpoint,
  defaultMaxRetries: 3,
);

final myCleanup = JobDescriptor(
  id: 'cleanup_temp_files',
  type: JobType.periodic,
  defaultInterval: Duration(hours: 1),
);
```

Handlers are registered separately via `HandlerRegistry.register`.

### 3. Running and Scheduling (via `ZenJobsExecutor`)

Do not call `ZenJobs.trigger` or `ZenJobs.handleRequest` directly — these operations are forbidden on the registry. Instead, instantiate `ZenJobsExecutor` with an explicit mode and use it to schedule or expose webhooks.

Development (in-memory, uses internal `TestExecutor`):

```dart
final jobs = ZenJobsExecutor.development();
await jobs.start();
await jobs.schedule(myEmail, payload: {'userId': 'u123'});
await jobs.shutdown();
```

Production (Firestore persistence via internal `LocalExecutor`):

```dart
final store = JobStore(); // Firestore-backed client
final telemetry = TelemetryClient(...);
final jobs = ZenJobsExecutor.production(
  store: store,
  telemetry: telemetry,
);
await jobs.start();
await jobs.schedule(myCleanup);
await jobs.shutdown();
```

Executors own web adapters and the HTTP handling surface — they are responsible
for translating incoming Cloud Tasks webhooks into calls to `JobRunner`. Internal executors live under `package:dartzen_jobs/src/internal/...` and are intended for tests and framework wiring only.

### 4. Handling Web Requests (Executor owned)

Executors decide how to expose webhook endpoints (HTTP handlers) and how to
map incoming requests to `JobRunner` executions. The public registry (`ZenJobs`)
does not implement HTTP handling directly; this separation prevents accidental
runtime behavior in library consumers.

If you need a simple local server in development, use the development-mode
executor or wrap the internal `LocalExecutor` with a small HTTP handler that
parses the request and calls `executor.schedule(...)` or
`JobRunner.execute(...)` as appropriate.

## 🧠 Core Concepts

### Job Configuration (Firestore)

Job behavior is controlled by specific documents in the `jobs` collection in Firestore. This allows you to:

- **Enable/Disable** jobs instantly.
- **Change Schedules** (Cron or Interval) without deploying code.
- **View Status** (`lastRun`, `status`) for monitoring.

### The Master Job

For **Periodic** jobs, you don't need to set up a Cloud Scheduler for _every single job_. Instead, you set up **one** Cloud Scheduler job to trigger the "Master Job" (ID: `zen_master_scheduler`) every minute. This job checks all periodic jobs in Firestore and runs the ones that are due.

## 📡 Telemetry

Every job emits:

- `job.started`
- `job.succeeded`
- `job.failed`

With:

- jobId
- executionId
- duration
- error (if any)

Jobs are observable by default.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
