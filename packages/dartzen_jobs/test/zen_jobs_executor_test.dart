import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:dartzen_jobs/src/job_store.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStore extends Mock implements JobStore {}

class MockTelemetry extends Mock implements TelemetryClient {}

void main() {
  test('create development returns development executor', () {
    final exec = ZenJobsExecutor.create(mode: ZenJobsMode.development);
    expect(exec.mode, ZenJobsMode.development);
  });

  test('create production without params throws', () {
    expect(
      () => ZenJobsExecutor.create(mode: ZenJobsMode.production),
      throwsArgumentError,
    );
  });

  test('production factory sets mode and delegates', () {
    // initialize global registry before creating production executor
    ZenJobs.instance = ZenJobs();

    final store = MockStore();
    final telemetry = MockTelemetry();
    final exec = ZenJobsExecutor.production(store: store, telemetry: telemetry);
    expect(exec.mode, ZenJobsMode.production);
  });

  test('register and registerHandler delegate to registries', () {
    final store = MockStore();
    final telemetry = MockTelemetry();
    final exec = ZenJobsExecutor.production(store: store, telemetry: telemetry);

    // initialize global registry instance for the test
    ZenJobs.instance = ZenJobs();

    const descriptor = JobDescriptor(id: 'j1', type: JobType.endpoint);
    exec.register(descriptor);
    // registry lives in ZenJobs (global) and public tests validate registration
    expect(ZenJobs.instance.descriptors.containsKey('j1'), isTrue);

    // handler registration should populate the HandlerRegistry
    exec.registerHandler('j1', (ctx) async {});
    expect(HandlerRegistry.get('j1'), isNotNull);
  });
}
