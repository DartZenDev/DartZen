import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/src/job_runner.dart';
import 'package:dartzen_jobs/src/models/job_config.dart';
import 'package:dartzen_jobs/src/models/job_definition.dart';
import 'package:dartzen_jobs/src/models/job_status.dart';
import 'package:dartzen_jobs/src/models/job_type.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/jobs_mocks.dart';

void main() {
  late JobRunner runner;
  late MockJobStore store;
  late MockTelemetryClient telemetry;
  final registry = <String, JobDefinition>{};

  setUp(() {
    store = MockJobStore();
    telemetry = MockTelemetryClient();
    runner = JobRunner(store, registry, telemetry);
    registry.clear();
    registerFallbackValue(
      TelemetryEvent(
        name: 'test',
        timestamp: DateTime.now(),
        scope: 'test',
        source: TelemetrySource.job,
      ),
    );
    registerFallbackValue(DateTime.now());
    registerFallbackValue(JobStatus.success);
    when(() => telemetry.emitEvent(any())).thenAnswer((_) async {});
  });

  test('executes job when enabled and dates valid', () async {
    bool executed = false;
    final job = JobDefinition(
      id: 'test_job',
      type: JobType.endpoint,
      handler: (ctx) async {
        executed = true;
      },
    );
    registry['test_job'] = job;

    when(() => store.getJobConfig('test_job')).thenAnswer(
      (_) async => const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
    );
    when(
      () => store.updateJobState(
        any(),
        lastRun: any(named: 'lastRun'),
        lastStatus: any(named: 'lastStatus'),
        currentRetries: any(named: 'currentRetries'),
      ),
    ).thenAnswer((_) async => const ZenResult.ok(null));

    final result = await runner.execute('test_job');

    expect(result.isSuccess, isTrue);
    expect(executed, isTrue);
    verify(
      () => store.updateJobState(
        'test_job',
        lastRun: any(named: 'lastRun'),
        lastStatus: JobStatus.success,
        currentRetries: 0,
      ),
    ).called(1);
    verify(() => telemetry.emitEvent(any())).called(2);
  });

  test('skips job when disabled', () async {
    bool executed = false;
    final job = JobDefinition(
      id: 'test_job',
      type: JobType.endpoint,
      handler: (ctx) async {
        executed = true;
      },
    );
    registry['test_job'] = job;

    when(() => store.getJobConfig('test_job')).thenAnswer(
      (_) async =>
          const ZenResult.ok(JobConfig(id: 'test_job', enabled: false)),
    );
    when(
      () => store.updateJobState(any(), lastStatus: any(named: 'lastStatus')),
    ).thenAnswer((_) async => const ZenResult.ok(null));

    final result = await runner.execute('test_job');

    expect(result.isSuccess, isTrue);
    expect(executed, isFalse);
    verify(
      () => store.updateJobState(
        'test_job',
        lastStatus: JobStatus.skippedDisabled,
      ),
    ).called(1);
  });

  test('skips job when ended', () async {
    final job = JobDefinition(
      id: 'test_job',
      type: JobType.endpoint,
      handler: (ctx) async {},
    );
    registry['test_job'] = job;

    when(() => store.getJobConfig('test_job')).thenAnswer(
      (_) async => ZenResult.ok(
        JobConfig(
          id: 'test_job',
          enabled: true,
          endAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
    );
    when(
      () => store.updateJobState(any(), lastStatus: any(named: 'lastStatus')),
    ).thenAnswer((_) async => const ZenResult.ok(null));

    final result = await runner.execute('test_job');

    expect(result.isSuccess, isTrue);
    verify(
      () =>
          store.updateJobState('test_job', lastStatus: JobStatus.skippedEnded),
    ).called(1);
  });

  test('respects dependencies', () async {
    final job = JobDefinition(
      id: 'downstream',
      type: JobType.endpoint,
      handler: (ctx) async {},
    );
    registry['downstream'] = job;

    when(() => store.getJobConfig('downstream')).thenAnswer(
      (_) async => const ZenResult.ok(
        JobConfig(id: 'downstream', enabled: true, dependencies: ['upstream']),
      ),
    );
    when(() => store.getJobConfig('upstream')).thenAnswer(
      (_) async => const ZenResult.ok(
        JobConfig(
          id: 'upstream',
          enabled: true,
          lastStatus: JobStatus.failure, // Dependency failed
        ),
      ),
    );
    when(
      () => store.updateJobState(any(), lastStatus: any(named: 'lastStatus')),
    ).thenAnswer((_) async => const ZenResult.ok(null));

    final result = await runner.execute('downstream');

    expect(result.isSuccess, isTrue);
    verify(
      () => store.updateJobState(
        'downstream',
        lastStatus: JobStatus.skippedDependencyFailed,
      ),
    ).called(1);
  });

  test('increments retries on failure', () async {
    final job = JobDefinition(
      id: 'fail_job',
      type: JobType.endpoint,
      handler: (ctx) async {
        throw Exception('Boom');
      },
    );
    registry['fail_job'] = job;

    when(() => store.getJobConfig('fail_job')).thenAnswer(
      (_) async => const ZenResult.ok(JobConfig(id: 'fail_job', enabled: true)),
    );
    when(
      () => store.updateJobState(
        any(),
        lastRun: any(named: 'lastRun'),
        lastStatus: any(named: 'lastStatus'),
        currentRetries: any(named: 'currentRetries'),
      ),
    ).thenAnswer((_) async => const ZenResult.ok(null));

    final result = await runner.execute('fail_job');

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, contains('Boom'));

    verify(
      () => store.updateJobState(
        'fail_job',
        lastRun: any(named: 'lastRun'),
        lastStatus: JobStatus.failure,
        currentRetries: 1,
      ),
    ).called(1);
  });
}
