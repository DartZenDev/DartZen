import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:test/test.dart';

void main() {
  late ZenJobs zenJobs;

  setUp(() {
    // Use the registry-only instance for tests. Runtime behavior is provided
    // by Executors in production; this package enforces that separation.
    zenJobs = ZenJobs();
  });

  test('registers a job descriptor', () {
    const descriptor = JobDescriptor(id: 'test-job', type: JobType.endpoint,
    );
    zenJobs.register(descriptor);
    expect(zenJobs.descriptors['test-job'], descriptor);
  });
}
