import 'models/job_definition.dart';

/// Minimal public `Executor` contract.
///
/// `Executor` implementations own runtime responsibilities that are
/// deliberately excluded from the public `ZenJobs` registry: scheduling,
/// adapter integration, lifecycle, and state persistence.
abstract class Executor {
  /// Start any resources consumed by the executor (adapters, timers, clients).
  Future<void> start();

  /// Gracefully shut down the executor and release resources.
  Future<void> shutdown();

  /// Schedule or request a job execution for the provided [descriptor].
  ///
  /// The [descriptor] must be registered in `ZenJobs` and a handler must be
  /// available in `HandlerRegistry`. [payload] is optional runtime data.
  Future<void> schedule(
    JobDescriptor descriptor, {
    Map<String, dynamic>? payload,
  });
}
