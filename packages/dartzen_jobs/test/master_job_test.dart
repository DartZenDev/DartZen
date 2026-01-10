import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/src/master_job.dart';
import 'package:dartzen_jobs/src/models/job_config.dart';
import 'package:dartzen_jobs/src/models/job_context.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/jobs_mocks.dart';

void main() {
  late MasterJob masterJob;
  late MockJobStore store;
  late MockTelemetryClient telemetry;
  final executedJobs = <String>[];

  setUp(() {
    store = MockJobStore();
    telemetry = MockTelemetryClient();
    executedJobs.clear();

    masterJob = MasterJob(store, telemetry, (
      jobId, {
      payload,
      currentTime,
    }) async {
      executedJobs.add(jobId);
      return const ZenResult.ok(null);
    });

    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      TelemetryEvent(
        name: 'test',
        timestamp: DateTime.now(),
        scope: 'test',
        source: TelemetrySource.server,
      ),
    );
    when(() => telemetry.emitEvent(any())).thenAnswer((_) async {});
  });

  test('triggers periodic jobs that are due', () async {
    final now = DateTime.now();
    final dueJob = JobConfig(
      id: 'due_job',
      enabled: true,
      interval: const Duration(minutes: 5),
      lastRun: now.subtract(const Duration(minutes: 6)),
    );
    final notDueJob = JobConfig(
      id: 'not_due_job',
      enabled: true,
      interval: const Duration(minutes: 10),
      lastRun: now.subtract(const Duration(minutes: 5)),
    );

    when(
      () => store.getEnabledPeriodicJobs(),
    ).thenAnswer((_) async => ZenResult.ok([dueJob, notDueJob]));

    final result = await masterJob.run(
      JobContext(jobId: 'master', executionTime: now, attempt: 1),
    );

    expect(result.isSuccess, isTrue);
    expect(executedJobs, contains('due_job'));
    expect(executedJobs, isNot(contains('not_due_job')));
    verify(() => telemetry.emitEvent(any())).called(1);
  });
}
