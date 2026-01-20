/// Unified background and scheduled jobs system for DartZen.
///
/// IMPORTANT: This package provides the low-level job registry and executor
/// primitives used by the DartZen job runtime. It is not intended to be used
/// directly by application code. Applications should not call handlers,
/// web adapters, or executor internals directly — instead, instantiate an
/// appropriate `Executor` (for example `TestExecutor`, `LocalExecutor`, or a
/// cloud executor) and interact with jobs via the executor surface.
///
/// Treat this package as a runtime/internal library: public application code
/// should prefer higher-level, opinionated entrypoints (for example packages
/// that provide hosted executors or your application's own orchestration
/// component).
///
/// This package provides a robust, Zen-compliant job execution framework:
/// - **Unified API**: Single way to define Endpoint, Scheduled, and Periodic jobs.
/// - **Serverless Native**: Designed for Cloud Run, Cloud Tasks, and Cloud Scheduler.
/// - **Cost Aware**: Optimizes Cloud Run container starts via "Master Job" batching.
/// - **Developer Experience**: Simulation mode for local development (no cloud dependencies).
///
/// This package adheres to Zen Architecture:
/// - **Explicit**: No magic annotations or build steps.
/// - **Simplicity**: Logic is clear, transparent, and easy to debug.
/// - **GCP-First**: Leverages specific GCP services for reliability.
///
/// It does NOT contain:
/// - **Complex Logic**: Business logic should reside in your domain packages.
/// - **Magic Triggers**: All triggers are explicit via `ZenJobs.trigger` or webhooks.
library;

export 'src/errors.dart';
export 'src/executor.dart';
export 'src/handler_registry.dart';
export 'src/local_executor.dart';
export 'src/models/job_config.dart';
export 'src/models/job_context.dart';
export 'src/models/job_definition.dart';
export 'src/models/job_policy.dart';
export 'src/models/job_status.dart';
export 'src/models/job_type.dart';
export 'src/test_executor.dart';
export 'src/zen_jobs.dart';
