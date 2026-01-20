import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:test/test.dart';

void main() {
  late ZenJobs zenJobs;

  setUp(() {
    // Use the registry-only instance for tests. Runtime behavior is provided
    // by Executors in production; this package enforces that separation.
    zenJobs = ZenJobs();
  });

  test('handleRequest throws MissingDescriptorException', () async {
    expect(
      () async => await zenJobs.handleRequest({'jobId': 'any'}),
      throwsA(isA<MissingDescriptorException>()),
    );
  });
}
