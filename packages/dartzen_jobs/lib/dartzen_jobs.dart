/// Unified background and scheduled jobs system for DartZen.
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

export 'src/cloud_tasks_adapter.dart' show JobSubmission, CloudTaskRequest;
export 'src/models/job_config.dart';
export 'src/models/job_context.dart';
export 'src/models/job_definition.dart';
export 'src/models/job_status.dart';
export 'src/models/job_type.dart';
export 'src/zen_jobs.dart';
