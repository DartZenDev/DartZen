import 'dart:async';

import '../errors.dart';
import '../handler_registry.dart';
import '../models/job_context.dart';
import '../models/job_definition.dart';
import 'executor.dart';

/// Internal executor intended for local testing and examples.
///
/// `TestExecutor` invokes registered handlers synchronously and does not
/// perform persistence or retry logic. It is useful for examples and tests
/// where a full production executor is not required.
///
/// Supports optional zone service injection for testing zone-aware tasks.
class TestExecutor implements Executor {
  final Map<String, dynamic>? _zoneServices;
  var _running = false;

  /// Creates a [TestExecutor].
  ///
  /// [zoneServices] optional map of services to inject into execution zones.
  TestExecutor({Map<String, dynamic>? zoneServices})
    : _zoneServices = zoneServices;

  @override
  Future<void> start() async {
    _running = true;
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

    final handler = HandlerRegistry.get(descriptor.id);
    if (handler == null) {
      throw MissingDescriptorException(
        'No handler registered for job: ${descriptor.id}',
      );
    }

    final now = DateTime.now().toUtc();
    final context = JobContext(
      jobId: descriptor.id,
      executionTime: now,
      attempt: 1,
      payload: payload,
    );

    // Execute handler with zone services if configured
    if (_zoneServices == null || _zoneServices.isEmpty) {
      await handler(context);
    } else {
      await runZoned(
        () => handler(context),
        zoneValues: _zoneServices,
      );
    }
  }
}
