import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:test/test.dart';

/// Test implementation of AggregationTask for testing purposes
class TestAggregationTask extends AggregationTask<Map<String, dynamic>> {
  final String id;
  final List<String> data;

  TestAggregationTask({required this.id, required this.data});

  @override
  Map<String, dynamic> toPayload() => {
        'id': id,
        'data': data,
      };

  factory TestAggregationTask.fromPayload(Map<String, dynamic> payload) => TestAggregationTask(
      id: payload['id'] as String,
      data: List<String>.from(payload['data'] as List),
    );

  @override
  Future<ZenResult<Map<String, dynamic>>> execute(JobContext context) async {
    final logger = Zone.current['dartzen.logger'] as List<String>?;
    logger?.add('Executing task: $id');

    // Simulate work
    await Future<void>.delayed(Duration.zero);

    return ZenResult.ok({'result': 'success', 'data': data});
  }
}

/// Task that accesses multiple zone services
class MultiServiceTask extends AggregationTask<String> {
  final String operation;

  MultiServiceTask(this.operation);

  @override
  Map<String, dynamic> toPayload() => {'operation': operation};

  factory MultiServiceTask.fromPayload(Map<String, dynamic> payload) => MultiServiceTask(payload['operation'] as String);

  @override
  Future<ZenResult<String>> execute(JobContext context) async {
    final executor = Zone.current['dartzen.executor'] as bool?;
    final logger = Zone.current['dartzen.logger'] as List<String>?;
    final httpClient = Zone.current['dartzen.http.client'] as String?;
    final aiService = Zone.current['dartzen.ai.service'] as String?;

    if (executor != true) {
      return const ZenResult.err(
        ZenUnknownError('Not in executor zone'),
      );
    }

    logger?.add('operation: $operation');

    return ZenResult.ok(
      'executor=$executor, logger=${logger != null}, '
      'http=$httpClient, ai=$aiService',
    );
  }
}

/// Task that throws an error during execution
class ErrorTask extends AggregationTask<void> {
  @override
  Map<String, dynamic> toPayload() => {'type': 'error'};

  @override
  Future<ZenResult<void>> execute(JobContext context) async {
    throw Exception('Intentional error');
  }
}

void main() {
  group('AggregationTask', () {
    group('toPayload / fromPayload contract', () {
      test('toPayload produces JSON-serializable output', () {
        final task = TestAggregationTask(
          id: 'test-123',
          data: ['item1', 'item2'],
        );

        final payload = task.toPayload();

        expect(payload, isA<Map<String, dynamic>>());
        expect(payload['id'], equals('test-123'));
        expect(payload['data'], equals(['item1', 'item2']));
        expect(payload['data'], isA<List<dynamic>>());
        expect(
          (payload['data'] as List<dynamic>).every((dynamic e) => e is String),
          isTrue,
        );
      });

      test('fromPayload correctly reconstructs task', () {
        final originalPayload = {
          'id': 'test-456',
          'data': ['a', 'b', 'c'],
        };

        final task = TestAggregationTask.fromPayload(originalPayload);

        expect(task.id, equals('test-456'));
        expect(task.data, equals(['a', 'b', 'c']));
      });

      test('round-trip serialization/deserialization works', () {
        final original = TestAggregationTask(
          id: 'round-trip',
          data: ['test'],
        );

        final payload = original.toPayload();
        final reconstructed = TestAggregationTask.fromPayload(payload);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.data, equals(original.data));
      });

      test('payload contains only JSON-serializable types', () {
        final task = TestAggregationTask(
          id: 'json-test',
          data: ['valid'],
        );

        final payload = task.toPayload();

        // Verify all values are JSON-serializable
        expect(payload['id'], isA<String>());
        expect(payload['data'], isA<List>());
        expect(payload['data'].every((e) => e is String), isTrue);
      });
    });

    group('execute with zone services', () {
      test('has access to zone services when executed in zone', () async {
        final task = TestAggregationTask(id: 'test', data: []);
        final logger = <String>[];

        final context = JobContext(
          jobId: 'test-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        final result = await runZoned(
          () => task.execute(context),
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.logger': logger,
          },
        );

        expect(result.isSuccess, isTrue);
        expect(logger, contains('Executing task: test'));
      });

      test('can access multiple zone services', () async {
        final task = MultiServiceTask('process-data');
        final logger = <String>[];

        final context = JobContext(
          jobId: 'multi-service-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        final result = await runZoned(
          () => task.execute(context),
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.logger': logger,
            'dartzen.http.client': 'mock-http-client',
            'dartzen.ai.service': 'mock-ai-service',
          },
        );

        expect(result.isSuccess, isTrue);
        expect(logger, contains('operation: process-data'));
        final output = result.dataOrNull!;
        expect(output, contains('executor=true'));
        expect(output, contains('http=mock-http-client'));
        expect(output, contains('ai=mock-ai-service'));
      });

      test('executes successfully without zone services', () async {
        final task = TestAggregationTask(id: 'no-zone', data: ['test']);

        final context = JobContext(
          jobId: 'no-zone-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        // Execute without zone setup
        final result = await task.execute(context);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!['result'], equals('success'));
      });

      test('preserves zone context across async boundaries', () async {
        final task = TestAggregationTask(id: 'async', data: []);
        final logger = <String>[];

        final context = JobContext(
          jobId: 'async-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        var zoneCheckBefore = false;
        var zoneCheckAfter = false;

        final result = await runZoned(
          () async {
            zoneCheckBefore = Zone.current['dartzen.executor'] == true;
          await Future<void>.delayed(Duration.zero);
            zoneCheckAfter = Zone.current['dartzen.executor'] == true;
            return task.execute(context);
          },
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.logger': logger,
          },
        );

        expect(zoneCheckBefore, isTrue);
        expect(zoneCheckAfter, isTrue);
        expect(result.isSuccess, isTrue);
      });

      test('errors in execute are caught and can be wrapped', () async {
        final task = ErrorTask();

        final context = JobContext(
          jobId: 'error-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        ZenResult<void>? result;
        try {
          await task.execute(context);
        } catch (e) {
          // Task threw an error - executor would catch and wrap this
          result = ZenResult.err(
            ZenUnknownError('Task failed: $e'),
          );
        }

        expect(result, isNotNull);
        expect(result!.isFailure, isTrue);
      });
    });

    group('isInExecutorZone', () {
      test('returns true when in executor zone', () {
        final result = runZoned(
          () => AggregationTask.isInExecutorZone,
          zoneValues: {'dartzen.executor': true},
        );

        expect(result, isTrue);
      });

      test('returns false when dartzen.executor is not set', () {
        final result = runZoned(
          () => AggregationTask.isInExecutorZone,
          zoneValues: {'other.key': 'value'},
        );

        expect(result, isFalse);
      });

      test('returns false when not in zone', () {
        // Not running in any special zone
        expect(AggregationTask.isInExecutorZone, isFalse);
      });

      test('returns false when dartzen.executor is not true', () {
        final result = runZoned(
          () => AggregationTask.isInExecutorZone,
          zoneValues: {'dartzen.executor': false},
        );

        expect(result, isFalse);
      });
    });

    group('getService', () {
      test('returns service when in executor zone', () {
        final mockLogger = <String>[];

        final logger = runZoned(
          () => AggregationTask.getService<List<String>>('dartzen.logger'),
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.logger': mockLogger,
          },
        );

        expect(logger, equals(mockLogger));
      });

      test('returns null when not in executor zone', () {
        final logger = runZoned(
          () => AggregationTask.getService<List<String>>('dartzen.logger'),
          zoneValues: {'dartzen.logger': <String>[]},
        );

        expect(logger, isNull);
      });

      test('returns null when service key not found', () {
        final service = runZoned(
          () => AggregationTask.getService<String>('missing.service'),
          zoneValues: {'dartzen.executor': true},
        );

        expect(service, isNull);
      });

      test('returns null when not in any zone', () {
        final service = AggregationTask.getService<String>('dartzen.logger');
        expect(service, isNull);
      });

      test('properly casts to expected type', () {
        final result = runZoned(
          () => AggregationTask.getService<String>('dartzen.test'),
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.test': 'test-value',
          },
        );

        expect(result, isA<String>());
        expect(result, equals('test-value'));
      });
    });

    group('integration scenarios', () {
      test('simulates full task lifecycle with zone services', () async {
        final task = TestAggregationTask(
          id: 'lifecycle-test',
          data: ['item1', 'item2'],
        );

        // 1. Serialize for storage
        final payload = task.toPayload();
        expect(payload, isA<Map<String, dynamic>>());

        // 2. Rehydrate from payload (simulates loading from Firestore)
        final rehydrated = TestAggregationTask.fromPayload(payload);
        expect(rehydrated.id, equals(task.id));
        expect(rehydrated.data, equals(task.data));

        // 3. Execute with zone services
        final logger = <String>[];
        final context = JobContext(
          jobId: 'lifecycle-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        final result = await runZoned(
          () => rehydrated.execute(context),
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.logger': logger,
          },
        );

        expect(result.isSuccess, isTrue);
        expect(logger, isNotEmpty);
      });

      test('task can conditionally use services based on availability',
          () async {
        final task = MultiServiceTask('conditional-services');

        final context = JobContext(
          jobId: 'conditional-job',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        // Execute with partial services
        final result = await runZoned(
          () => task.execute(context),
          zoneValues: {
            'dartzen.executor': true,
            'dartzen.logger': <String>[],
            // http and ai services not provided
          },
        );

        expect(result.isSuccess, isTrue);
        final output = result.dataOrNull!;
        expect(output, contains('executor=true'));
        expect(output, contains('http=null'));
        expect(output, contains('ai=null'));
      });

      test('multiple tasks can execute concurrently with isolated zones',
          () async {
        final task1 = TestAggregationTask(id: 'task1', data: ['a']);
        final task2 = TestAggregationTask(id: 'task2', data: ['b']);

        final logger1 = <String>[];
        final logger2 = <String>[];

        final context1 = JobContext(
          jobId: 'job1',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        final context2 = JobContext(
          jobId: 'job2',
          executionTime: DateTime.now(),
          attempt: 1,
        );

        // Execute concurrently with different zone services
        final results = await Future.wait([
          runZoned(
            () => task1.execute(context1),
            zoneValues: {
              'dartzen.executor': true,
              'dartzen.logger': logger1,
            },
          ),
          runZoned(
            () => task2.execute(context2),
            zoneValues: {
              'dartzen.executor': true,
              'dartzen.logger': logger2,
            },
          ),
        ]);

        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isTrue);
        expect(logger1, contains('Executing task: task1'));
        expect(logger2, contains('Executing task: task2'));
        // Verify zone isolation - logger1 shouldn't have task2's logs
        expect(logger1, isNot(contains('Executing task: task2')));
        expect(logger2, isNot(contains('Executing task: task1')));
      });
    });
  });
}
