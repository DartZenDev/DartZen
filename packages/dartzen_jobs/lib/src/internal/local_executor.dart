import 'package:dartzen_telemetry/dartzen_telemetry.dart';

import '../errors.dart';
import '../job_runner.dart';
import '../job_store.dart';
import '../models/job_definition.dart';
import '../zen_jobs.dart';
import 'executor.dart';

/// Internal executor that runs jobs locally while updating persistent state
/// through [JobStore]. Suitable for single-host environments where Firestore
/// stores job configuration and runtime state.
class LocalExecutor implements Executor {
  final JobStore _store;
  final TelemetryClient _telemetry;
  final Map<String, dynamic>? _zoneServices;
  late final JobRunner _runner;
  var _running = false;

  /// Creates a [LocalExecutor].
  ///
  /// [store] is used to persist and read job configuration/state.
  /// [telemetry] is used for emitting telemetry events. Both are required.
  /// [zoneServices] optional map of services to inject into execution zones.
  LocalExecutor({
    required JobStore store,
    required TelemetryClient telemetry,
    Map<String, dynamic>? zoneServices,
  }) : _store = store,
       _telemetry = telemetry,
       _zoneServices = zoneServices {
    _runner = JobRunner(
      _store,
      ZenJobs.instance.descriptors,
      _telemetry,
      zoneServices: _zoneServices,
    );
  }

  @override
  Future<void> start() async {
    _running = true;
    // No background tasks in this simple executor.
  }

  @override
  Future<void> shutdown() async {
    _running = false;
  }

  @override
  Future<void> schedule(
    JobDescriptor descriptor, {
    Map<String, dynamic>? payload,
  }) async {
    if (!_running) throw StateError('Executor not started');

    // Ensure descriptor is registered
    final registered = ZenJobs.instance.descriptors[descriptor.id];
    if (registered == null) {
      throw MissingDescriptorException(
        'Descriptor not registered: ${descriptor.id}',
      );
    }

    final result = await _runner.execute(descriptor.id, payload: payload);
    if (result.isFailure) {
      final err = result.errorOrNull;
      throw JobExecutionError('LocalExecutor failed: ${err?.message ?? err}');
    }
  }
}
