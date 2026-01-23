import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:dartzen_jobs/src/job_runner.dart';
import 'package:dartzen_jobs/src/job_store.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockJobStore extends Mock implements JobStore {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

void main() {
  late JobStore store;
  late TelemetryClient telemetry;
  late Map<String, JobDescriptor> registry;
  late JobRunner runner;

  setUp(() {
    store = MockJobStore();
    telemetry = MockTelemetryClient();
    registry = {};

    // Register fallback values for mocktail
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

  tearDown(HandlerRegistry.clear);

  group('JobRunner Zone Injection', () {
    test('executes handler without zone when no services configured', () async {
      const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
      registry['test_job'] = job;

      var wasInZone = false;
      HandlerRegistry.register('test_job', (ctx) async {
        // Check if we're in a zone with services
        wasInZone = Zone.current['dartzen.executor'] == true;
      });

      runner = JobRunner(store, registry, telemetry);

      when(() => store.getJobConfig('test_job')).thenAnswer(
        (_) async =>
            const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
      );
      when(
        () => store.updateJobState(
          any(),
          lastRun: any(named: 'lastRun'),
          lastStatus: any(named: 'lastStatus'),
          currentRetries: any(named: 'currentRetries'),
        ),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      await runner.execute('test_job');

      expect(wasInZone, isFalse);
    });

    test('injects services into zone when configured', () async {
      const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
      registry['test_job'] = job;

      var wasInZone = false;
      var foundService = false;

      HandlerRegistry.register('test_job', (ctx) async {
        // Check if we're in a zone with services
        wasInZone = Zone.current['dartzen.executor'] == true;
        foundService = Zone.current['dartzen.test.service'] == 'test-value';
      });

      runner = JobRunner(
        store,
        registry,
        telemetry,
        zoneServices: {
          'dartzen.executor': true,
          'dartzen.test.service': 'test-value',
        },
      );

      when(() => store.getJobConfig('test_job')).thenAnswer(
        (_) async =>
            const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
      );
      when(
        () => store.updateJobState(
          any(),
          lastRun: any(named: 'lastRun'),
          lastStatus: any(named: 'lastStatus'),
          currentRetries: any(named: 'currentRetries'),
        ),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      await runner.execute('test_job');

      expect(wasInZone, isTrue);
      expect(foundService, isTrue);
    });

    test('zone services accessible across async boundaries', () async {
      const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
      registry['test_job'] = job;

      var serviceBeforeAsync = false;
      var serviceAfterAsync = false;

      HandlerRegistry.register('test_job', (ctx) async {
        serviceBeforeAsync = Zone.current['dartzen.executor'] == true;

        // Simulate async operation
        await Future<void>.delayed(Duration.zero);

        serviceAfterAsync = Zone.current['dartzen.executor'] == true;
      });

      runner = JobRunner(
        store,
        registry,
        telemetry,
        zoneServices: {'dartzen.executor': true},
      );

      when(() => store.getJobConfig('test_job')).thenAnswer(
        (_) async =>
            const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
      );
      when(
        () => store.updateJobState(
          any(),
          lastRun: any(named: 'lastRun'),
          lastStatus: any(named: 'lastStatus'),
          currentRetries: any(named: 'currentRetries'),
        ),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      await runner.execute('test_job');

      expect(serviceBeforeAsync, isTrue);
      expect(serviceAfterAsync, isTrue);
    });

    test('multiple services can be injected', () async {
      const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
      registry['test_job'] = job;

      final capturedServices = <String, dynamic>{};

      HandlerRegistry.register('test_job', (ctx) async {
        capturedServices['executor'] = Zone.current['dartzen.executor'];
        capturedServices['logger'] = Zone.current['dartzen.logger'];
        capturedServices['http'] = Zone.current['dartzen.http.client'];
      });

      runner = JobRunner(
        store,
        registry,
        telemetry,
        zoneServices: {
          'dartzen.executor': true,
          'dartzen.logger': 'test-logger',
          'dartzen.http.client': 'test-client',
        },
      );

      when(() => store.getJobConfig('test_job')).thenAnswer(
        (_) async =>
            const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
      );
      when(
        () => store.updateJobState(
          any(),
          lastRun: any(named: 'lastRun'),
          lastStatus: any(named: 'lastStatus'),
          currentRetries: any(named: 'currentRetries'),
        ),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      await runner.execute('test_job');

      expect(capturedServices['executor'], isTrue);
      expect(capturedServices['logger'], equals('test-logger'));
      expect(capturedServices['http'], equals('test-client'));
    });

    test(
      'zone is isolated - services not accessible outside handler',
      () async {
        const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
        registry['test_job'] = job;

        HandlerRegistry.register('test_job', (ctx) async {
          // Inside handler - should have access
          expect(Zone.current['dartzen.executor'], isTrue);
        });

        runner = JobRunner(
          store,
          registry,
          telemetry,
          zoneServices: {'dartzen.executor': true},
        );

        when(() => store.getJobConfig('test_job')).thenAnswer(
          (_) async =>
              const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
        );
        when(
          () => store.updateJobState(
            any(),
            lastRun: any(named: 'lastRun'),
            lastStatus: any(named: 'lastStatus'),
            currentRetries: any(named: 'currentRetries'),
          ),
        ).thenAnswer((_) async => const ZenResult.ok(null));

        await runner.execute('test_job');

        // Outside handler - should NOT have access
        expect(Zone.current['dartzen.executor'], isNull);
      },
    );

    test('errors in handler propagate correctly through zone', () async {
      const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
      registry['test_job'] = job;

      HandlerRegistry.register('test_job', (ctx) async {
        // Verify we're in the zone
        expect(Zone.current['dartzen.executor'], isTrue);
        throw Exception('Handler error');
      });

      runner = JobRunner(
        store,
        registry,
        telemetry,
        zoneServices: {'dartzen.executor': true},
      );

      when(() => store.getJobConfig('test_job')).thenAnswer(
        (_) async =>
            const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
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

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<JobExecutionError>());
    });

    test(
      'backward compatibility - existing handlers work without zones',
      () async {
        const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
        registry['test_job'] = job;

        var executed = false;

        HandlerRegistry.register('test_job', (ctx) async {
          executed = true;
          // This handler doesn't use zone services at all
          expect(ctx.jobId, equals('test_job'));
        });

        // Create runner WITHOUT zone services (backward compatible)
        runner = JobRunner(store, registry, telemetry);

        when(() => store.getJobConfig('test_job')).thenAnswer(
          (_) async =>
              const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
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
      },
    );

    test('empty zone services map behaves like no zones', () async {
      const job = JobDescriptor(id: 'test_job', type: JobType.endpoint);
      registry['test_job'] = job;

      var wasInZone = false;

      HandlerRegistry.register('test_job', (ctx) async {
        wasInZone = Zone.current['dartzen.executor'] == true;
      });

      // Explicitly pass empty map
      runner = JobRunner(store, registry, telemetry, zoneServices: {});

      when(() => store.getJobConfig('test_job')).thenAnswer(
        (_) async =>
            const ZenResult.ok(JobConfig(id: 'test_job', enabled: true)),
      );
      when(
        () => store.updateJobState(
          any(),
          lastRun: any(named: 'lastRun'),
          lastStatus: any(named: 'lastStatus'),
          currentRetries: any(named: 'currentRetries'),
        ),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      await runner.execute('test_job');

      expect(wasInZone, isFalse);
    });
  });
}
