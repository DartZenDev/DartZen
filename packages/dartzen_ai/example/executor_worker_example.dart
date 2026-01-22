// ignore_for_file: avoid_print

/// Executor worker example showing Zone-based service injection.
///
/// This example is illustrative: real servers construct and inject the
/// `AIService` via DI. The executor worker runs task execution inside a
/// `Zone` that exposes the runtime-only service instance and a marker flag.
library;

void main() {
  print('Executor worker Zone injection example:');
  print('');

  print('The executor SHOULD execute tasks like this:\n');

  print("""
  // Pseudocode (server-side worker)
  final aiService = createAiService(...); // created by DI in the worker

  await runZonedGuarded(() async {
    // Inside this zone the executor runs the task. The task implementation
    // reads the runtime service from the Zone rather than carrying it in its
    // payload. This keeps task payloads serializable and re-hydratable.

    // Zone.current['dartzen.executor'] == true
    // Zone.current['dartzen.ai.service'] == aiService

    // Example: the executor receives a job envelope, rehydrates the task,
    // and invokes the task's execute() implementation here.
    final task = /* deserialize payload to task */ null;
    // await task.execute(); // task will access the AI service from the Zone
  }, (error, stack) {
    // handle unhandled errors
  }, zoneValues: {
    'dartzen.executor': true,
    'dartzen.ai.service': aiService,
  });
  """);

  print('');
  print('Task authors: implement `toPayload()` / `fromPayload()` and avoid');
  print('capturing runtime objects in your task constructor.');
}
