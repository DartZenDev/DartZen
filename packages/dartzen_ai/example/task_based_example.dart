// ignore_for_file: avoid_print

/// End-to-end guide for executor-only AI task execution.
library;

///
/// This demonstrates all 3 AI task types and the executor-only pattern.
///
/// ## The Executor-Only Model
///
/// All AI execution MUST go through ZenExecutor for these reasons:
/// - AI calls are expensive (network-bound, latency-heavy, billable)
/// - Direct execution blocks the event loop indefinitely
/// - Executor provides cost control, isolation, and cloud routing

/// - This is intentional and non-negotiable for DartZen servers
void main() {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║    Executor-Only AI Task Execution - Complete Guide        ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  print('STEP 1: Task Creation\n');

  print('All AI tasks extend ZenTask<Response>:\n');

  print('TextGenerationAiTask');
  print('  Generates text from prompts');
  print('  weight: heavy, latency: slow, retryable: true\n');

  print('EmbeddingsAiTask');
  print('  Generates vector embeddings');
  print('  weight: heavy, latency: slow, retryable: true\n');

  print('ClassificationAiTask');
  print('  Classifies text into labels');
  print('  weight: heavy, latency: slow, retryable: true\n');

  print('STEP 2: Task Descriptors\n');

  print('Each task declares an execution contract:\n');
  print('  • weight: TaskWeight.heavy (routes to jobs system)');
  print('  • latency: Latency.slow (documents expected duration)');
  print('  • retryable: true (safe to auto-retry)\n');

  print('STEP 3: Execution via ZenExecutor\n');

  print('Pattern:\n');
  print('  1. Create task instance\n');
  print('     final task = TextGenerationAiTask(');
  print('       prompt: "...",');
  print('       model: "...",');
  print('     );');
  print(
    '     // NOTE: Tasks are payload-only and must NOT carry runtime services.',
  );
  print('     // The executor injects `dartzen.ai.service` into the Zone when');
  print('     // executing the task (see executor integration docs).\n');
  print('  2. Pass to executor\n');
  print('     final result = await executor.execute(task);\n');
  print('  3. Handle response\n');
  print('     print(result.text);  // Strongly typed\n');

  print('STEP 4: Why Executor-Only?\n');

  print('Direct Service Calls (FORBIDDEN):\n');
  print('  ✗ aiService.textGeneration(req) blocks event loop');
  print('  ✗ Bypasses budget enforcement');
  print('  ✗ Prevents distributed execution');
  print('  ✗ Makes testing and isolation hard\n');

  print('Executor-Based Execution (REQUIRED):\n');
  print('  ✓ Deterministic routing (weight-based)');
  print('  ✓ Automatic cost enforcement');
  print('  ✓ Cloud jobs dispatch (non-blocking)');
  print('  ✓ Built-in retry & telemetry\n');

  print('STEP 5: Enforcement Mechanisms\n');

  print('The executor-only pattern is enforced by:\n');
  print('  1. @internal annotation on AIService, AIClient, etc.');
  print('  2. analyzer error: invalid_use_of_internal_member');
  print('  3. Package exports restricted to tasks only');
  print('  4. Runtime assertions in debug mode');
  print('  5. Comprehensive documentation\n');

  print('STEP 6: Service Injection\n');

  print('AIService is never instantiated by user code.\n');
  print('It\'s created and injected by the DI framework:\n');
  print('  • Production: Injected by server initialization');
  print('  • Tests: Mock injected via test harness');
  print('  • Never: Direct instantiation or @internal imports\n');

  print('════════════════════════════════════════════════════════════');
  print('See README.md for complete API reference and examples');
  print('════════════════════════════════════════════════════════════');
}
