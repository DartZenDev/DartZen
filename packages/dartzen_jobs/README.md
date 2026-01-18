# DartZen Jobs

[![pub package](https://img.shields.io/pub/v/dartzen_jobs.svg)](https://pub.dev/packages/dartzen_jobs)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Deterministic background execution for serverless Dart.**

A unified background and scheduled jobs system for DartZen applications, designed for Cloud Run without blocking, surprises, or hidden concurrency.

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

### 1. Initialization

Initialize `ZenJobs` with your Cloud Tasks configuration. In development (`dzIsPrd = false`), this uses a simulation mode.

```dart
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';

void main() {
  ZenJobs.instance = ZenJobs(
    projectId: 'my-project',
    locationId: 'us-central1',
    queueId: 'default',
    serviceUrl: 'https://my-service-url.run.app',
  );

  // Register jobs
  ZenJobs.instance.register(myEmailJob);
  ZenJobs.instance.register(myCleanupJob);
}
```

### 2. Defining Jobs

Create `JobDefinition`s for your tasks.

```dart
final myEmailJob = JobDefinition(
  id: 'send_welcome_email',
  type: JobType.endpoint,
  handler: (context) async {
    final userId = context.payload?['userId'];
    print('Sending email to $userId');
    // Implement logic...
  },
);

final myCleanupJob = JobDefinition(
  id: 'cleanup_temp_files',
  type: JobType.periodic,
  defaultInterval: Duration(hours: 1),
  handler: (context) async {
    print('Cleaning up temp files...');
  },
);
```

### 3. Triggering Jobs

Trigger endpoint jobs anywhere in your code.

```dart
// Helper method often used in domain logic
Future<void> registerUser(String userId) async {
  // ... create user ...

  // Trigger background job
  await ZenJobs.instance.trigger(
    'send_welcome_email',
    payload: {'userId': userId},
  );
}
```

No background magic. No hidden retries.

### 4. Handling Requests

In your server entry point (e.g., Shelf handler), route requests to `ZenJobs`.

```dart
// In your server request handler
Future<Response> handleJobRequest(Request request) async {
  final body = await request.readAsString();
  final status = await ZenJobs.instance.handleRequest(body);

  return Response(status);
}
```

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
