import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:dartzen_jobs/src/internal/test_executor.dart';
import 'package:test/test.dart';

void main() {
  test('TestExecutor invokes registered handler with payload', () async {
    // Prepare descriptor and registry
    const descriptor = JobDescriptor(id: 'job-1', type: JobType.endpoint);
    ZenJobs.instance = ZenJobs();
    ZenJobs.instance.register(descriptor);

    var called = false;
    Map<String, dynamic>? receivedPayload;

    HandlerRegistry.register(descriptor.id, (context) async {
      called = true;
      receivedPayload = context.payload;
    });

    final executor = TestExecutor();
    await executor.start();
    await executor.schedule(descriptor, payload: {'x': 1});
    await executor.shutdown();

    expect(called, isTrue);
    expect(receivedPayload, containsPair('x', 1));

    HandlerRegistry.clear();
  });
}
