import 'dart:convert';

import 'package:dartzen_executor/src/models/job_envelope.dart';
import 'package:dartzen_executor/src/models/task.dart';
import 'package:dartzen_executor/src/models/task_rehydration.dart';
import 'package:dartzen_executor/src/models/task_worker.dart';
import 'package:test/test.dart';

void main() {
  tearDown(TaskFactoryRegistry.clear);

  group('End-to-End Rehydration Flow', () {
    test(
      'full cycle: task → envelope → serialize → deserialize → rehydrate → execute',
      () async {
        // 1. Register factory
        TaskFactoryRegistry.register<String>(
          'WorkerHeavyTask',
          (payload) => WorkerHeavyTask(
            input: payload['input'] as String,
            multiplier: payload['multiplier'] as int,
          ),
        );

        // 2. Create original task
        final originalTask = WorkerHeavyTask(input: 'test', multiplier: 3);

        // 3. Convert to envelope (what executor does before dispatch)
        final envelope = JobEnvelope.fromTask(originalTask);

        // 4. Serialize to JSON (what happens in HTTP transport)
        final json = jsonEncode(envelope.toJson());
        expect(json, contains('WorkerHeavyTask'));
        expect(json, contains('"input":"test"'));
        expect(json, contains('"multiplier":3'));

        // 5. Deserialize in worker (simulate Cloud Run receiving request)
        final receivedEnvelope = JobEnvelope.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );

        expect(receivedEnvelope.taskType, 'WorkerHeavyTask');
        expect(receivedEnvelope.payload['input'], 'test');
        expect(receivedEnvelope.payload['multiplier'], 3);

        // 6. Rehydrate and execute in worker context
        final result = await rehydrateAndExecute(receivedEnvelope);

        // 7. Verify result
        expect(result.isSuccess, isTrue);
        final value = result.fold((v) => v, (e) => throw e);
        expect(value, 'test-test-test'); // 'test' * 3
      },
    );

    test('worker helper handles unknown task type gracefully', () async {
      const envelope = JobEnvelope(
        taskType: 'UnknownTask',
        metadata: {'id': 'unknown-123', 'weight': 'heavy'},
        payload: {},
      );

      final result = await rehydrateAndExecute(envelope);

      expect(result.isFailure, isTrue);
      final error = result.fold((v) => throw v as Object, (e) => e);
      expect(error.message, contains('No factory registered'));
    });

    test('worker helper handles task execution errors', () async {
      // Register factory that creates failing task
      TaskFactoryRegistry.register<String>(
        'FailingTask',
        (payload) => FailingTask(),
      );

      const envelope = JobEnvelope(
        taskType: 'FailingTask',
        metadata: {'id': 'failing-123', 'weight': 'heavy'},
        payload: {},
      );

      final result = await rehydrateAndExecute(envelope);

      expect(result.isFailure, isTrue);
      final error = result.fold((v) => throw v as Object, (e) => e);
      expect(error.message, contains('Failed to rehydrate or execute'));
    });

    test('simulate Cloud Run handler pattern', () async {
      // Setup: Register task factory (done once at worker startup)
      TaskFactoryRegistry.register<Map<String, dynamic>>(
        'DataProcessingTask',
        (payload) =>
            DataProcessingTask(data: List<int>.from(payload['data'] as List)),
      );

      // Simulate: Executor creates envelope and dispatches
      final task = DataProcessingTask(data: const [1, 2, 3, 4, 5]);
      final envelope = JobEnvelope.fromTask(task);
      final requestBody = jsonEncode(envelope.toJson());

      // Simulate: Cloud Run receives HTTP request
      final receivedJson = jsonDecode(requestBody) as Map<String, dynamic>;
      final receivedEnvelope = JobEnvelope.fromJson(receivedJson);

      // Simulate: Worker handler processes request
      final result = await rehydrateAndExecute(receivedEnvelope);

      // Verify: Result matches expected computation
      expect(result.isSuccess, isTrue);
      final stats = result.fold(
        (v) => v as Map<String, dynamic>,
        (e) => throw e,
      );
      expect(stats['count'], 5);
      expect(stats['sum'], 15);
      expect(stats['average'], 3.0);
    });
  });
}

// Test task 1: String multiplication
class WorkerHeavyTask extends ZenTask<String> {
  WorkerHeavyTask({required this.input, required this.multiplier});

  final String input;
  final int multiplier;

  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.heavy);

  @override
  Map<String, dynamic> toPayload() => {
    'input': input,
    'multiplier': multiplier,
  };

  @override
  Future<String> execute() async => List.filled(multiplier, input).join('-');
}

// Test task 2: Failing task
class FailingTask extends ZenTask<String> {
  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.heavy);

  @override
  Map<String, dynamic> toPayload() => {};

  @override
  Future<String> execute() async {
    throw Exception('Task execution failed intentionally');
  }
}

// Test task 3: Data processing
class DataProcessingTask extends ZenTask<Map<String, dynamic>> {
  DataProcessingTask({required this.data});

  final List<int> data;

  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.heavy);

  @override
  Map<String, dynamic> toPayload() => {'data': data};

  @override
  Future<Map<String, dynamic>> execute() async {
    final sum = data.reduce((a, b) => a + b);
    return {'count': data.length, 'sum': sum, 'average': sum / data.length};
  }
}
