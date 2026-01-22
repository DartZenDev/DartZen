import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:dartzen_jobs/src/internal/local_executor.dart';
import 'package:dartzen_jobs/src/job_store.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:test/test.dart';

class _FakeTelemetryStore implements TelemetryStore {
  final List<TelemetryEvent> events = [];

  @override
  Future<void> addEvent(TelemetryEvent event) async {
    events.add(event);
  }

  @override
  Future<List<TelemetryEvent>> queryEvents({
    String? userId,
    String? sessionId,
    String? correlationId,
    String? scope,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async => events;
}

class _FakeJobStore implements JobStore {
  late JobConfig lastConfig;
  String? lastUpdatedJobId;
  JobStatus? lastUpdatedStatus;

  _FakeJobStore({required JobConfig config}) {
    lastConfig = config;
  }

  @override
  Future<ZenResult<JobConfig>> getJobConfig(String jobId) async {
    if (jobId == lastConfig.id) return ZenResult.ok(lastConfig);
    return const ZenResult.err(ZenNotFoundError('not found'));
  }

  @override
  Future<ZenResult<void>> updateJobState(
    String jobId, {
    DateTime? lastRun,
    DateTime? nextRun,
    JobStatus? lastStatus,
    int? currentRetries,
  }) async {
    lastUpdatedJobId = jobId;
    lastUpdatedStatus = lastStatus;
    return const ZenResult.ok(null);
  }

  // Remaining JobStore methods are unused in this test. Provide stubs if needed.
  @override
  Future<ZenResult<List<JobConfig>>> getEnabledPeriodicJobs() =>
      Future.value(const ZenResult.ok([]));
}

void main() {
  test('LocalExecutor executes handler and updates state', () async {
    // Clear global registries
    HandlerRegistry.clear();

    // Prepare descriptor and register
    const desc = JobDescriptor(id: 'job_x', type: JobType.endpoint);
    ZenJobs.instance = ZenJobs();
    ZenJobs.instance.register(desc);

    var invoked = false;
    HandlerRegistry.register('job_x', (ctx) async {
      invoked = true;
      expect(ctx.jobId, 'job_x');
      expect(ctx.attempt, 1);
      expect(ctx.payload?['k'], 'v');
    });

    const config = JobConfig(id: 'job_x', enabled: true);
    final fakeStore = _FakeJobStore(config: config);

    final telemetryStore = _FakeTelemetryStore();
    final telemetry = TelemetryClient(telemetryStore);

    final executor = LocalExecutor(store: fakeStore, telemetry: telemetry);
    await executor.start();

    await executor.schedule(desc, payload: {'k': 'v'});

    expect(invoked, isTrue);
    expect(fakeStore.lastUpdatedJobId, 'job_x');
    expect(fakeStore.lastUpdatedStatus, JobStatus.success);

    await executor.shutdown();
    HandlerRegistry.clear();
  });
}
