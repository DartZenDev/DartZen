import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/src/handler_registry.dart';
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
  final registry = <String, JobDescriptor>{};

  setUp(() {
    store = MockJobStore();
    telemetry = MockTelemetryClient();
    runner = JobRunner(store, registry, telemetry);
    registry.clear();
    // Ensure handler registry is clean for each test
    HandlerRegistry.clear();
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
    var executed = false;
    const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
    registry['test_job'] = job;

    // Register a handler that marks execution
    HandlerRegistry.register('test_job', (ctx) async {
      executed = true;
      return;
    });

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
    var executed = false;
    const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
    registry['test_job'] = job;
    HandlerRegistry.register('test_job', (ctx) async {
      executed = true;
      return;
    });

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
    const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
    registry['test_job'] = job;
    HandlerRegistry.register('test_job', (ctx) async {});

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
    const job = JobDescriptor(id: 'downstream', type: JobType.endpoint);
    registry['downstream'] = job;
    HandlerRegistry.register('downstream', (ctx) async {});

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
    const job = JobDescriptor(id: 'fail_job', type: JobType.endpoint);
    registry['fail_job'] = job;

    HandlerRegistry.register('fail_job', (ctx) async {
      throw Exception('Boom');
    });

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
