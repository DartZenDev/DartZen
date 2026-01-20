// Suppress doc and unused-constructor-parameter lint noise for this small
// compatibility-focused model file.
// ignore_for_file: public_member_api_docs, avoid_unused_constructor_parameters

import 'job_context.dart';
import 'job_policy.dart';
import 'job_type.dart';

/// Function signature for job execution logic. Kept for compatibility.
typedef JobHandler = Future<void> Function(JobContext context);

/// Metadata-only descriptor for a job.
///
/// This class is deliberately free of executable logic. Handlers must be
/// registered separately via `HandlerRegistry`. Descriptors declare identity
/// and policy metadata only.
class JobDescriptor {
  final String id;
  final JobType type;
  final String? defaultCron;
  final Duration? defaultInterval;
  final int? defaultPriority;
  final int? defaultMaxRetries;
  final JobPolicy policy;

  const JobDescriptor({
    required this.id,
    required this.type,
    this.defaultCron,
    this.defaultInterval,
    this.defaultPriority,
    this.defaultMaxRetries,
    this.policy = const JobPolicy(),
  });
}

/// Backwards-compatible wrapper that accepts an optional handler parameter
/// but delegates to `JobDescriptor` semantics. Use `JobDescriptor` instead.
class JobDefinition extends JobDescriptor {
  const JobDefinition({
    required super.id,
    required super.type,
    JobHandler? handler,
    super.defaultCron,
    super.defaultInterval,
    super.defaultPriority,
    super.defaultMaxRetries,
    super.policy,
  });
}
