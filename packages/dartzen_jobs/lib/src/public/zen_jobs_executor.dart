import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import '../handler_registry.dart';
import '../internal/executor.dart';
import '../internal/local_executor.dart';
import '../internal/test_executor.dart';
import '../job_store.dart';
import '../models/job_context.dart';
import '../models/job_definition.dart';
import '../zen_jobs.dart';

/// Explicit runtime modes for `ZenJobsExecutor`.
enum ZenJobsMode {
  /// Development mode: in-memory executor, no persistence.
  development,

  /// Production mode: Firestore-backed executor with persistence.
  production,
}

/// Single public entry point for executing and scheduling jobs.
///
/// Concrete executors are internal. Users must choose a mode explicitly to
/// avoid accidental executor selection or environment-based guessing.
class ZenJobsExecutor implements Executor {
  ZenJobsExecutor._(this.mode, this._delegate);

  /// Explicit runtime mode.
  final ZenJobsMode mode;

  /// Internal executor performing the actual work.
  final Executor _delegate;

  /// Development mode executor backed by the in-memory [TestExecutor].
  factory ZenJobsExecutor.development() =>
      ZenJobsExecutor._(ZenJobsMode.development, TestExecutor());

  /// Production mode executor backed by [LocalExecutor].
  factory ZenJobsExecutor.production({
    required JobStore store,
    required TelemetryClient telemetry,
  }) => ZenJobsExecutor._(
    ZenJobsMode.production,
    LocalExecutor(store: store, telemetry: telemetry),
  );

  /// Creates an executor by explicit [mode].
  ///
  /// For production, both [store] and [telemetry] are required. For
  /// development, no additional parameters are needed.
  factory ZenJobsExecutor.create({
    required ZenJobsMode mode,
    JobStore? store,
    TelemetryClient? telemetry,
  }) {
    switch (mode) {
      case ZenJobsMode.development:
        return ZenJobsExecutor.development();
      case ZenJobsMode.production:
        if (store == null || telemetry == null) {
          throw ArgumentError('Production mode requires store and telemetry.');
        }
        return ZenJobsExecutor.production(store: store, telemetry: telemetry);
    }
  }

  /// Registers a job descriptor in the global registry.
  ///
  /// This convenience method keeps registry access colocated with the
  /// executor at the call site.
  void register(JobDescriptor descriptor) {
    ZenJobs.instance.register(descriptor);
  }

  /// Registers a handler in the global handler registry.
  void registerHandler(
    String jobId,
    Future<void> Function(JobContext) handler,
  ) {
    HandlerRegistry.register(jobId, handler);
  }

  @override
  Future<void> start() => _delegate.start();

  @override
  Future<void> shutdown() => _delegate.shutdown();

  @override
  Future<void> schedule(
    JobDescriptor descriptor, {
    Map<String, dynamic>? payload,
  }) => _delegate.schedule(descriptor, payload: payload);
}
