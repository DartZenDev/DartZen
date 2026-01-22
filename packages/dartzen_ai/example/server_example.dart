// ignore_for_file: avoid_print

/// Example demonstrating task-based AI execution via ZenExecutor.
library;

///
/// This example shows how to properly structure AI tasks for executor-only
/// execution on the server side. All AI work MUST go through ZenExecutor.
///
/// ## Pattern
///
/// 1. Create task instances with required parameters
/// 2. Pass tasks to ZenExecutor.execute(task)
/// 3. Executor handles routing based on task weight

/// 4. Results come back as typed responses
///
/// ## Enforcement
///
/// - ✅ Tasks are declared as `weight: heavy`
/// - ✅ Routing is automatic (to jobs system)
/// - ✅ Budget enforcement at execution time
/// - ✅ Direct service calls forbidden (@internal)
void main() {
  print('=== Executor-Only AI Task Execution ===\n');

  print('Task Pattern Examples:\n');

  print('1. TextGenerationAiTask');
  print('   final task = TextGenerationAiTask(');
  print('     prompt: "Your prompt here",');
  print('     model: "gemini-1.5-pro",');
  print('   );');
  print('   // Do NOT pass runtime services into task payloads. The executor');
  print(
    '   // will inject the AI service into the execution Zone at runtime.\n',
  );

  print('2. EmbeddingsAiTask');
  print('   final task = EmbeddingsAiTask(');
  print('     texts: ["text1", "text2"],');
  print('     model: "text-embedding-004",');
  print('   );\n');

  print('3. ClassificationAiTask');
  print('   final task = ClassificationAiTask(');
  print('     text: "Your text here",');
  print('     labels: ["positive", "negative"],');
  print('     model: "gemini-1.5-pro",');
  print('   );\n');

  print('Execution Pattern:\n');

  print('   final executor = ZenExecutor(config: executorConfig);');
  print('   final result = await executor.execute(task);');
  print('   // Executor routes based on weight → jobs system\n');

  print('Cache-backed usage store wiring:\n');
  print('  // Create a cache client via CacheFactory (e.g. memorystore)');
  print('  // final cache = await CacheFactory.create(cacheConfig);');
  print('  // final store = await CacheAIUsageStore.connect(cacheConfig);');
  print('  // final enforcer = AIBudgetEnforcer(usageStore: store);\n');

  print('All tasks declare:');
  print('  • weight: heavy');
  print('  • latency: slow');
  print('  • retryable: true\n');

  print('This ensures:');
  print('  ✓ Event loop never blocks');
  print('  ✓ Automatic cost routing');
  print('  ✓ Distributed execution');
  print('  ✓ Built-in retry support\n');

  print('=== See README.md for full documentation ===');
}
