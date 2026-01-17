// ignore_for_file: avoid_print

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_executor/dartzen_executor.dart';

// Example light task: simple async operation
@ZenTaskDescriptor(weight: TaskWeight.light, latency: Latency.fast)
class FetchDataTask extends ZenTask<String> {
  FetchDataTask(this.url);

  final String url;

  @override
  TaskMetadata get metadata =>
      TaskMetadata(weight: TaskWeight.light, id: 'fetch_$url');

  @override
  Future<String> execute() async {
    // Simulate async I/O
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'Data from $url';
  }
}

// Example medium task: CPU-bound computation
@ZenTaskDescriptor(weight: TaskWeight.medium, latency: Latency.medium)
class ComputePrimeTask extends ZenTask<int> {
  ComputePrimeTask(this.n);

  final int n;

  @override
  TaskMetadata get metadata =>
      TaskMetadata(weight: TaskWeight.medium, id: 'compute_prime_$n');

  @override
  Future<int> execute() async => _computeNthPrime(n);

  int _computeNthPrime(int n) {
    if (n < 1) return 0;
    int count = 0;
    int candidate = 2;

    while (count < n) {
      if (_isPrime(candidate)) {
        count++;
        if (count == n) return candidate;
      }
      candidate++;
    }
    return candidate;
  }

  bool _isPrime(int num) {
    if (num < 2) return false;
    for (int i = 2; i * i <= num; i++) {
      if (num % i == 0) return false;
    }
    return true;
  }
}

// Example heavy task: long-running job
@ZenTaskDescriptor(weight: TaskWeight.heavy, latency: Latency.slow)
class ProcessLargeDatasetTask extends ZenTask<void> {
  ProcessLargeDatasetTask(this.datasetId);

  final String datasetId;

  @override
  TaskMetadata get metadata =>
      TaskMetadata(weight: TaskWeight.heavy, id: 'process_dataset_$datasetId');

  @override
  Future<void> execute() async {
    // Heavy work delegated to jobs system
  }

  @override
  Map<String, dynamic> toPayload() => {
    'datasetId': datasetId,
    'timestamp': DateTime.now().toIso8601String(),
    'processingMode': 'batch',
  };
}

// Mock job dispatcher for this example
class ExampleJobDispatcher implements JobDispatcher {
  @override
  Future<ZenResult<void>> dispatch({
    required String jobId,
    required String queueId,
    required String serviceUrl,
    required Map<String, dynamic> payload,
  }) async {
    print('  [DISPATCHER] Dispatched to:');
    print('    - jobId: $jobId');
    print('    - queueId: $queueId');
    print('    - serviceUrl: $serviceUrl');
    print('    - payload keys: ${payload.keys.toList()}');
    return const ZenResult.ok(null);
  }
}

void main() async {
  print('=== DartZen Executor Example ===\n');

  // 1. Create executor with EXPLICIT DI (required dependencies)
  final dispatcher = ExampleJobDispatcher();
  final executor = ZenExecutor(
    config: const ZenExecutorConfig(
      queueId: 'my-task-queue',
      serviceUrl: 'https://my-service.run.app',
    ),
    dispatcher: dispatcher,
  );

  print('Executor configured with:');
  print('  - queueId: ${executor.config.queueId}');
  print('  - serviceUrl: ${executor.config.serviceUrl}');
  print('  - dispatcher: ${dispatcher.runtimeType.toString()}');
  print('  - mediumPolicy timeout: 1s\n');

  // 2. Execute light task (inline, non-blocking)
  print('--- Light Task ---');
  final lightTask = FetchDataTask('https://api.example.com/data');
  final lightResult = await executor.execute(lightTask);

  lightResult.fold(
    (data) => print('✓ Light task result: $data'),
    (error) => print('✗ Light task error: ${error.message}'),
  );

  // 3. Execute medium task (local isolate)
  print('\n--- Medium Task ---');
  final mediumTask = ComputePrimeTask(1000);
  final mediumResult = await executor.execute(mediumTask);

  mediumResult.fold(
    (prime) => print('✓ Medium task result: 1000th prime is $prime'),
    (error) => print('✗ Medium task error: ${error.message}'),
  );

  // 4. Dispatch heavy task via injected dispatcher
  print('\n--- Heavy Task (Dispatch via Injected Dispatcher) ---');
  final heavyTask = ProcessLargeDatasetTask('dataset-42');
  final heavyResult = await executor.execute(heavyTask);

  heavyResult.fold(
    (_) => print(
      '✓ Heavy task dispatched successfully '
      '(actual result is async via jobs system)',
    ),
    (error) => print('✗ Heavy task dispatch error: ${error.message}'),
  );

  // 5. Demonstrate explicit override
  print('\n--- Heavy Task with Per-Call Override ---');
  final overriddenTask = ProcessLargeDatasetTask('dataset-99');
  const overrides = ExecutionOverrides(
    queueId: 'special-priority-queue',
    serviceUrl: 'https://special.run.app',
  );

  final overriddenResult = await executor.execute(
    overriddenTask,
    overrides: overrides,
  );

  overriddenResult.fold(
    (_) => print(
      '✓ Overridden heavy task dispatched successfully '
      '(actual result is async via jobs system)',
    ),
    (error) => print('✗ Overridden task error: ${error.message}'),
  );

  print('\n=== Key Principles Demonstrated ===');
  print('1. [DI Pattern] JobDispatcher injected, not magically resolved');
  print(
    '2. [No Implicit Defaults] queueId, serviceUrl explicit at construction',
  );
  print(
    '3. [Strict Routing] Task weight enforces execution path (no fallback)',
  );
  print(
    '4. [Fail-Fast] Medium timeout is enforced; exceeding it is hard error',
  );
  print('5. [Pure Router] Executor routes only; dispatch logic in dispatcher');
  print('6. [Schema Contract] Job envelope is fixed, validated structure');

  print('\n=== Example Complete ===');
}
