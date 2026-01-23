import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:test/test.dart';

// A minimal heavy task that can be serialized and rehydrated.
class EchoHeavyTask extends ZenTask<String> {
  EchoHeavyTask(this.message);

  final String message;

  @override
  ZenTaskDescriptor get descriptor =>
      const ZenTaskDescriptor(weight: TaskWeight.heavy);

  @override
  Future<String> execute() async => 'echo:$message';

  @override
  Map<String, dynamic> toPayload() => {'message': message};

  static ZenTask<String> fromPayload(Map<String, dynamic> json) =>
      EchoHeavyTask(json['message'] as String);
}

void main() {
  group('TaskFactoryRegistry', () {
    setUp(TaskFactoryRegistry.clear);

    test('registers and rehydrates task from JobEnvelope', () async {
      // Register factory
      TaskFactoryRegistry.register<String>(
        'EchoHeavyTask',
        EchoHeavyTask.fromPayload,
      );

      // Create task and envelope
      final original = EchoHeavyTask('hello');
      final env = JobEnvelope.fromTask(original);

      // Rehydrate via registry
      final task = TaskFactoryRegistry.create(env.taskType, env.payload);

      expect(task, isNotNull);
      expect(task, isA<EchoHeavyTask>());

      // Execute rehydrated task deterministically
      final result = await (task as ZenTask<String>).invokeInternal();
      expect(result, 'echo:hello');
    });

    test('returns null when factory missing', () {
      const env = JobEnvelope(
        taskType: 'UnknownTask',
        metadata: {'id': 'x', 'weight': 'heavy', 'schemaVersion': 1},
        payload: {},
      );

      final task = TaskFactoryRegistry.create(env.taskType, env.payload);
      expect(task, isNull);
    });
  });
}
