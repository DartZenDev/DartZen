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
class TestExecutor implements Executor {
  var _running = false;

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

    await handler(context);
  }
}
