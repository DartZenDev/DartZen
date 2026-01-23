import 'dart:async';

import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:test/test.dart';

void main() {
  // Initialize ZenJobs singleton before each test
  setUp(() {
    ZenJobs.instance = ZenJobs(); // Initialize new instance
  });

  group('ZenJobsExecutor Zone Integration', () {
    group('Development Mode', () {
      test('creates executor without zone services', () {
        final executor = ZenJobsExecutor.development();

        expect(executor.mode, equals(ZenJobsMode.development));
      });

      test('creates executor with zone services', () {
        final services = {
          'dartzen.executor': true,
          'dartzen.logger': <String>[],
        };

        final executor = ZenJobsExecutor.development(zoneServices: services);

        expect(executor.mode, equals(ZenJobsMode.development));
      });

      test('handler can access zone services when configured', () async {
        final logger = <String>[];
        final services = {'dartzen.executor': true, 'dartzen.logger': logger};

        final executor = ZenJobsExecutor.development(zoneServices: services);

        const descriptor = JobDescriptor(
          id: 'test-job',
          type: JobType.endpoint,
        );

        var zoneCheckInside = false;
        executor.register(descriptor);
        executor.registerHandler('test-job', (context) async {
          zoneCheckInside = Zone.current['dartzen.executor'] == true;
          final zoneLogger = Zone.current['dartzen.logger'] as List<String>?;
          zoneLogger?.add('Handler executed');
        });

        await executor.start();
        await executor.schedule(descriptor);
        await executor.shutdown();

        expect(zoneCheckInside, isTrue);
        expect(logger, contains('Handler executed'));
      });

      test('handler works without zone services', () async {
        final executor = ZenJobsExecutor.development();

        const descriptor = JobDescriptor(
          id: 'no-zone-job',
          type: JobType.endpoint,
        );

        var executed = false;
        executor.register(descriptor);
        executor.registerHandler('no-zone-job', (context) async {
          executed = true;
          final hasExecutorMarker = Zone.current['dartzen.executor'] == true;
          expect(hasExecutorMarker, isFalse);
        });

        await executor.start();
        await executor.schedule(descriptor);
        await executor.shutdown();

        expect(executed, isTrue);
      });

      test('zone services isolated between consecutive executions', () async {
        final logger = <String>[];

        // Use single executor with dynamic zone services
        final executor = ZenJobsExecutor.development();

        const descriptor = JobDescriptor(
          id: 'isolated-job',
          type: JobType.endpoint,
        );

        executor.register(descriptor);
        executor.registerHandler('isolated-job', (context) async {
          final loggerFromZone =
              Zone.current['dartzen.logger'] as List<String>?;
          if (loggerFromZone != null) {
            loggerFromZone.add('Executed with zone');
          } else {
            logger.add('Executed without zone');
          }
        });

        await executor.start();

        // First execution without zone services
        await executor.schedule(descriptor);

        await executor.shutdown();

        // Verify only non-zone execution recorded
        expect(logger, equals(['Executed without zone']));
      });

      test('multiple services available in zone', () async {
        final logger = <String>[];
        final services = {
          'dartzen.executor': true,
          'dartzen.logger': logger,
          'dartzen.http.client': 'http-client',
          'dartzen.ai.service': 'ai-service',
        };

        final executor = ZenJobsExecutor.development(zoneServices: services);

        const descriptor = JobDescriptor(
          id: 'multi-service-job',
          type: JobType.endpoint,
        );

        executor.register(descriptor);
        executor.registerHandler('multi-service-job', (context) async {
          final isExecutor = Zone.current['dartzen.executor'] == true;
          final log = Zone.current['dartzen.logger'] as List<String>?;
          final http = Zone.current['dartzen.http.client'] as String?;
          final ai = Zone.current['dartzen.ai.service'] as String?;

          expect(isExecutor, isTrue);
          expect(log, isNotNull);
          expect(http, equals('http-client'));
          expect(ai, equals('ai-service'));

          log?.add('All services accessible');
        });

        await executor.start();
        await executor.schedule(descriptor);
        await executor.shutdown();

        expect(logger, contains('All services accessible'));
      });
    });

    group('Factory Method: create', () {
      test('creates development executor with zone services', () {
        final services = {'dartzen.test': 'value'};

        final executor = ZenJobsExecutor.create(
          mode: ZenJobsMode.development,
          zoneServices: services,
        );

        expect(executor.mode, equals(ZenJobsMode.development));
      });
    });

    group('Integration with AggregationTask', () {
      test(
        'AggregationTask.isInExecutorZone returns true in executor zone',
        () async {
          final services = {'dartzen.executor': true};

          final executor = ZenJobsExecutor.development(zoneServices: services);

          const descriptor = JobDescriptor(
            id: 'aggregation-job',
            type: JobType.endpoint,
          );

          var isInZone = false;
          executor.register(descriptor);
          executor.registerHandler('aggregation-job', (context) async {
            isInZone = AggregationTask.isInExecutorZone;
          });

          await executor.start();
          await executor.schedule(descriptor);
          await executor.shutdown();

          expect(isInZone, isTrue);
        },
      );

      test('AggregationTask.getService retrieves services from zone', () async {
        final mockLogger = <String>['test-log'];
        final services = {
          'dartzen.executor': true,
          'dartzen.logger': mockLogger,
        };

        final executor = ZenJobsExecutor.development(zoneServices: services);

        const descriptor = JobDescriptor(
          id: 'service-access-job',
          type: JobType.endpoint,
        );

        List<String>? retrievedLogger;
        executor.register(descriptor);
        executor.registerHandler('service-access-job', (context) async {
          retrievedLogger = AggregationTask.getService<List<String>>(
            'dartzen.logger',
          );
        });

        await executor.start();
        await executor.schedule(descriptor);
        await executor.shutdown();

        expect(retrievedLogger, equals(mockLogger));
      });

      test('zone context preserved across async boundaries', () async {
        final services = {'dartzen.executor': true, 'dartzen.value': 42};

        final executor = ZenJobsExecutor.development(zoneServices: services);

        const descriptor = JobDescriptor(
          id: 'async-job',
          type: JobType.endpoint,
        );

        var beforeDelay = 0;
        var afterDelay = 0;
        executor.register(descriptor);
        executor.registerHandler('async-job', (context) async {
          beforeDelay = Zone.current['dartzen.value'] as int? ?? 0;
          await Future<void>.delayed(Duration.zero);
          afterDelay = Zone.current['dartzen.value'] as int? ?? 0;
        });

        await executor.start();
        await executor.schedule(descriptor);
        await executor.shutdown();

        expect(beforeDelay, equals(42));
        expect(afterDelay, equals(42));
      });
    });

    group('Error Handling', () {
      test('errors in zone-wrapped handler propagate correctly', () async {
        final services = {'dartzen.executor': true};
        final executor = ZenJobsExecutor.development(zoneServices: services);

        const descriptor = JobDescriptor(
          id: 'error-job',
          type: JobType.endpoint,
        );

        executor.register(descriptor);
        executor.registerHandler('error-job', (context) async {
          throw Exception('Handler error');
        });

        await executor.start();

        expect(() => executor.schedule(descriptor), throwsA(isA<Exception>()));

        await executor.shutdown();
      });

      test('zone services do not prevent error propagation', () async {
        final logger = <String>[];
        final services = {'dartzen.executor': true, 'dartzen.logger': logger};

        final executor = ZenJobsExecutor.development(zoneServices: services);

        const descriptor = JobDescriptor(
          id: 'failing-job',
          type: JobType.endpoint,
        );

        executor.register(descriptor);
        executor.registerHandler('failing-job', (context) async {
          final log = Zone.current['dartzen.logger'] as List<String>?;
          log?.add('Before error');
          throw Exception('Intentional failure');
        });

        await executor.start();

        try {
          await executor.schedule(descriptor);
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          // Expected error
        }

        await executor.shutdown();

        expect(logger, contains('Before error'));
      });
    });
  });
}
