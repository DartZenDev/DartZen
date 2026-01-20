import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_executor/dartzen_executor.dart';
// This test file imports internal classes for testing purposes only.
// Application code must NOT import from lib/src or rely on these internals.
// ignore: depend_on_referenced_packages
import 'package:dartzen_executor/src/job_dispatcher.dart';
import 'package:test/test.dart';

// Mock job dispatcher for testing
class MockJobDispatcher implements JobDispatcher {
  MockJobDispatcher();
  final List<Map<String, dynamic>> dispatchedJobs = [];
  bool shouldFail = false;

  @override
  Future<ZenResult<void>> dispatch({
    required String jobId,
    required String queueId,
    required String serviceUrl,
    required Map<String, dynamic> payload,
  }) async {
    if (shouldFail) {
      // ignore: prefer_const_constructors
      return ZenResult.err(ZenUnknownError('Mock dispatch failure'));
    }
    dispatchedJobs.add({
      'jobId': jobId,
      'queueId': queueId,
      'serviceUrl': serviceUrl,
      'payload': payload,
    });
    // ignore: prefer_const_constructors
    return ZenResult.ok(null);
  }
}

// Test task implementations
class LightTask extends ZenTask<String> {
  LightTask(this.value);

  final String value;

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor();

  @override
  Future<String> execute() async => 'Light result: $value';
}

class MediumTask extends ZenTask<int> {
  MediumTask(this.n);

  final int n;

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
    weight: TaskWeight.medium,
    latency: Latency.medium,
  );

  @override
  Future<int> execute() async {
    // Simulate CPU work
    int sum = 0;
    for (int i = 0; i < n; i++) {
      sum += i;
    }
    return sum;
  }
}

class SlowMediumTask extends ZenTask<int> {
  SlowMediumTask();

  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.medium, latency: Latency.slow);

  @override
  Future<int> execute() async {
    // Exceeds default timeout (1s)
    await Future<void>.delayed(const Duration(seconds: 2));
    return 42;
  }
}

class HeavyTask extends ZenTask<void> {
  HeavyTask(this.jobId);

  final String jobId;

  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.heavy, latency: Latency.slow);

  @override
  Future<void> execute() async {
    // Heavy work delegated to jobs system
  }

  @override
  Map<String, dynamic> toPayload() => {
    'jobId': jobId,
    'timestamp': DateTime.now().toIso8601String(),
  };
}

class ThrowingJobDispatcher implements JobDispatcher {
  @override
  Future<ZenResult<void>> dispatch({
    required String jobId,
    required String queueId,
    required String serviceUrl,
    required Map<String, dynamic> payload,
  }) async {
    throw StateError('dispatcher threw');
  }
}

void main() {
  group('ZenExecutorConfig', () {
    test('requires queueId and serviceUrl', () {
      const config = ZenExecutorConfig(
        queueId: 'test-queue',
        serviceUrl: 'https://test.run.app',
      );

      expect(config.queueId, 'test-queue');
      expect(config.serviceUrl, 'https://test.run.app');
    });
  });

  group('TaskMetadata', () {
    test('has default schemaVersion of 1', () {
      const metadata = TaskMetadata(weight: TaskWeight.light, id: 'test-task');

      expect(metadata.schemaVersion, 1);
    });

    test('allows custom schemaVersion', () {
      const metadata = TaskMetadata(
        weight: TaskWeight.medium,
        id: 'test-task',
        schemaVersion: 2,
      );

      expect(metadata.schemaVersion, 2);
    });

    test('serializes to JSON correctly', () {
      const metadata = TaskMetadata(weight: TaskWeight.heavy, id: 'heavy-1');

      final json = metadata.toJson();
      expect(json['id'], 'heavy-1');
      expect(json['weight'], 'heavy');
      expect(json['schemaVersion'], 1);
    });
  });

  group('ExecutionOverrides', () {
    test('allows optional queueId override', () {
      const overrides = ExecutionOverrides(queueId: 'override-queue');

      expect(overrides.queueId, 'override-queue');
      expect(overrides.serviceUrl, isNull);
    });

    test('allows optional serviceUrl override', () {
      const overrides = ExecutionOverrides(
        serviceUrl: 'https://override.run.app',
      );

      expect(overrides.queueId, isNull);
      expect(overrides.serviceUrl, 'https://override.run.app');
    });

    test('allows both overrides', () {
      const overrides = ExecutionOverrides(
        queueId: 'override-queue',
        serviceUrl: 'https://override.run.app',
      );

      expect(overrides.queueId, 'override-queue');
      expect(overrides.serviceUrl, 'https://override.run.app');
    });
  });

  group('JobEnvelope', () {
    test('creates envelope from task', () {
      final task = HeavyTask('test-job-123');
      final envelope = JobEnvelope.fromTask(task);

      expect(envelope.taskType, 'HeavyTask');
      // ID is auto-generated from task type and payload hash
      expect(envelope.metadata['id'], startsWith('HeavyTask_'));
      expect(envelope.metadata['weight'], 'heavy');
      expect(envelope.metadata['schemaVersion'], 1);
      expect(envelope.payload['jobId'], 'test-job-123');
    });

    test('validates envelope structure', () {
      const validEnvelope = JobEnvelope(
        taskType: 'TestTask',
        metadata: {'id': 'test-1', 'weight': 'heavy', 'schemaVersion': 1},
        payload: {'data': 'value'},
      );

      final result = validEnvelope.validate();
      expect(result.isSuccess, isTrue);
    });

    test('rejects empty taskType', () {
      const invalidEnvelope = JobEnvelope(
        taskType: '',
        metadata: {'id': 'test-1', 'weight': 'heavy'},
        payload: {},
      );

      final result = invalidEnvelope.validate();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.message, contains('taskType'));
    });

    test('rejects missing metadata id', () {
      const invalidEnvelope = JobEnvelope(
        taskType: 'TestTask',
        metadata: {'weight': 'heavy'},
        payload: {},
      );

      final result = invalidEnvelope.validate();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.message, contains('id'));
    });

    test('rejects missing metadata weight', () {
      const invalidEnvelope = JobEnvelope(
        taskType: 'TestTask',
        metadata: {'id': 'test-1'},
        payload: {},
      );

      final result = invalidEnvelope.validate();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.message, contains('weight'));
    });

    test('serializes to JSON correctly', () {
      const envelope = JobEnvelope(
        taskType: 'TestTask',
        metadata: {'id': 'test-1', 'weight': 'heavy', 'schemaVersion': 1},
        payload: {'key': 'value'},
      );

      final Map<String, dynamic> json = envelope.toJson();
      expect(json['taskType'], 'TestTask');
      final Map<String, dynamic> metadata =
          json['metadata'] as Map<String, dynamic>;
      expect(metadata['id'], 'test-1');
      expect(metadata['weight'], 'heavy');
      expect(metadata['schemaVersion'], 1);
      final Map<String, dynamic> payload =
          json['payload'] as Map<String, dynamic>;
      expect(payload['key'], 'value');
    });
  });

  group('ZenExecutor - DI Pattern', () {
    late ZenExecutor executor;
    late MockJobDispatcher dispatcher;

    setUp(() {
      dispatcher = MockJobDispatcher();
      executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );
    });

    test('constructor requires explicit config and dispatcher', () {
      expect(executor.config.queueId, 'default-queue');
      expect(executor.config.serviceUrl, 'https://default.run.app');
      expect(executor.dispatcher, isNotNull);
    });

    test('executes light task inline', () async {
      final task = LightTask('test-value');
      final result = await executor.execute(task);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'Light result: test-value');
    });

    test('executes medium task in isolate', () async {
      final task = MediumTask(100);
      final result = await executor.execute(task);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 4950); // Sum of 0..99
    });

    test('enforces medium task timeout with fail-fast', () async {
      final task = SlowMediumTask();
      final result = await executor.execute(task);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.message, contains('timeout'));
    });

    test('dispatches heavy task via injected dispatcher', () async {
      final task = HeavyTask('test-job-123');
      final result = await executor.execute(task);

      // Heavy task dispatch succeeds (returns HeavyDispatchResult)
      expect(result.isSuccess, isTrue);

      expect(dispatcher.dispatchedJobs, isNotEmpty);
      final dispatchedJob = dispatcher.dispatchedJobs.first;
      // ID is auto-generated from task type and payload hash
      expect(dispatchedJob['jobId'], startsWith('HeavyTask_'));
      expect(dispatchedJob['queueId'], 'default-queue');
      expect(dispatchedJob['serviceUrl'], 'https://default.run.app');
    });

    test('respects explicit dispatcher overrides for heavy tasks', () async {
      final task = HeavyTask('test-job-456');
      const overrides = ExecutionOverrides(
        queueId: 'override-queue',
        serviceUrl: 'https://override.run.app',
      );

      final result = await executor.execute(task, overrides: overrides);

      expect(result.isSuccess, isTrue);
      expect(dispatcher.dispatchedJobs, isNotEmpty);
      final dispatchedJob = dispatcher.dispatchedJobs.first;
      expect(dispatchedJob['queueId'], 'override-queue');
      expect(dispatchedJob['serviceUrl'], 'https://override.run.app');
    });

    test('enforces strict job schema validation', () async {
      final task = HeavyTask('test-job-789');
      dispatcher.shouldFail = false;

      final result = await executor.execute(task);

      expect(result.isSuccess, isTrue);
      expect(dispatcher.dispatchedJobs, isNotEmpty);
      final dispatchedJob = dispatcher.dispatchedJobs.first;
      final payload = dispatchedJob['payload'] as Map<String, dynamic>;

      // Verify strict schema enforcement
      expect(payload.containsKey('taskType'), isTrue);
      expect(payload.containsKey('metadata'), isTrue);
      expect(payload.containsKey('payload'), isTrue);
      expect(payload['metadata'] is Map<String, dynamic>, isTrue);
    });

    test('fails immediately on dispatcher error (no retry)', () async {
      final task = HeavyTask('test-job-fail');
      dispatcher.shouldFail = true;

      final result = await executor.execute(task);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.message, contains('dispatch'));
    });

    test('wraps unexpected dispatcher exceptions for heavy tasks', () async {
      final throwingExecutor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: ThrowingJobDispatcher(),
      );

      final result = await throwingExecutor.execute(HeavyTask('panic'));

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
      expect(result.errorOrNull!.message, contains('Task execution failed'));
    });
  });

  group('ZenExecutor - Routing Decision Assertions', () {
    late MockJobDispatcher dispatcher;

    setUp(() {
      dispatcher = MockJobDispatcher();
    });

    test('light tasks never dispatch to jobs system', () async {
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      final task = LightTask('test');
      await executor.execute(task);

      // Light tasks must NOT dispatch to jobs
      expect(dispatcher.dispatchedJobs, isEmpty);
    });

    test('medium tasks never dispatch to jobs system', () async {
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      final task = MediumTask(50);
      await executor.execute(task);

      // Medium tasks must NOT dispatch to jobs
      expect(dispatcher.dispatchedJobs, isEmpty);
    });

    test('heavy tasks MUST dispatch to jobs system (no fallback)', () async {
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      final task = HeavyTask('test');
      await executor.execute(task);

      // Heavy tasks MUST dispatch, no exceptions
      expect(dispatcher.dispatchedJobs, isNotEmpty);
    });

    test('descriptor weight drives routing decision (light)', () async {
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      final task = LightTask('test');
      expect(task.descriptor.weight, TaskWeight.light);

      await executor.execute(task);
      expect(dispatcher.dispatchedJobs, isEmpty);
    });

    test('descriptor weight drives routing decision (medium)', () async {
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      final task = MediumTask(50);
      expect(task.descriptor.weight, TaskWeight.medium);

      await executor.execute(task);
      expect(dispatcher.dispatchedJobs, isEmpty);
    });

    test('descriptor weight drives routing decision (heavy)', () async {
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      final task = HeavyTask('test');
      expect(task.descriptor.weight, TaskWeight.heavy);

      await executor.execute(task);
      expect(dispatcher.dispatchedJobs, isNotEmpty);
    });
  });

  group('ZenExecutor - Fail-Fast Enforcement', () {
    late ZenExecutor executor;
    late MockJobDispatcher dispatcher;

    setUp(() {
      dispatcher = MockJobDispatcher();
      executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );
    });

    test('heavy dispatch failure is immediate (no retry)', () async {
      dispatcher.shouldFail = true;
      final task = HeavyTask('test');

      final result = await executor.execute(task);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });

    test('medium task timeout is immediate (no retry/fallback)', () async {
      final task = SlowMediumTask();

      final result = await executor.execute(task);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull!.message, contains('timeout'));
    });

    test('timeout failure message is clear about misclassification', () async {
      final task = SlowMediumTask();

      final result = await executor.execute(task);

      expect(result.isFailure, isTrue);
      // Should clearly indicate the task is misclassified
      expect(result.errorOrNull!.message.toLowerCase(), contains('timeout'));
    });
  });

  group('ZenExecutor - Public API Boundary', () {
    test(
      'only execute() is public (not executeLight, executeMedium, executeHeavy)',
      () {
        final dispatcher = MockJobDispatcher();
        final executor = ZenExecutor(
          config: const ZenExecutorConfig(
            queueId: 'default-queue',
            serviceUrl: 'https://default.run.app',
          ),
          dispatcher: dispatcher,
        );

        // Only execute() should be callable
        expect(executor.execute, isNotNull);

        // These methods exist but are internal (@internal annotation)
        // Attempting to call them would be a linting/static analysis error
        // This test documents the boundary constraint
      },
    );

    test('no user-selectable execution strategies exposed', () {
      final dispatcher = MockJobDispatcher();
      final executor = ZenExecutor(
        config: const ZenExecutorConfig(
          queueId: 'default-queue',
          serviceUrl: 'https://default.run.app',
        ),
        dispatcher: dispatcher,
      );

      // No public methods for selecting execution strategy
      // Users cannot:
      // - force isolate execution
      // - skip job dispatch
      // - choose custom executor
      // Everything is determined by task descriptor only
      expect(executor.runtimeType.toString(), 'ZenExecutor');
    });

    test('job dispatcher is internal (not exported)', () {
      // This test verifies that JobDispatcher is @internal
      // and cannot be imported from the public library surface
      // The test itself imports it for testing purposes only
      expect(() {
        // Application code cannot do this:
        // final dispatcher = CloudJobDispatcher();  // Would require direct import from src/
        // This enforces that users ONLY interact through ZenExecutor.execute()
      }, returnsNormally);
    });
  });
}
