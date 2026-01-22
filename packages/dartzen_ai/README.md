# DartZen AI

[![pub package](https://img.shields.io/pub/v/dartzen_ai.svg)](https://pub.dev/packages/dartzen_ai)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

> 🚧 **NOT PRODUCTION READY** — authentication and credential rotation are not finalized.

**Vertex AI / Gemini integration for DartZen, designed for non-blocking server runtimes with executor-only execution.**

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

---

## 🚫 **FORBIDDEN USAGE (WILL FAIL)**

### ❌ Do NOT instantiate AI services directly

```dart
// ❌ WRONG - This will fail with analyzer error (@internal violation)
final ai = AIService(client: ..., budgetEnforcer: ...);
final response = await ai.textGeneration(request);
```

### ❌ Do NOT call client directly

```dart
// ❌ WRONG - This will fail with analyzer error (@internal violation)
final client = AIClient(baseUrl: 'https://...');
final response = await client.textGeneration(prompt: '...');
```

### ❌ Do NOT use low-level HTTP client

```dart
// ❌ WRONG - This will fail with analyzer error (@internal violation)
final vertexAI = VertexAIClient(config: ...);
final response = await vertexAI.generateText(request);
```

**All services are marked `@internal` and not exported. Direct usage is impossible by design.**

---

## ✅ **CORRECT USAGE (ONLY VALID PATH)**

### All AI operations MUST be executed via `ZenExecutor`

```dart
import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_executor/dartzen_executor.dart';

// 1. Create AI task (task-based execution)
final task = TextGenerationAiTask(
  prompt: 'Write a haiku about distributed systems',
  model: 'gemini-pro',
);
// NOTE: Tasks are payload-only. Do NOT include runtime service instances
// in task constructors. The `ZenExecutor` injects the runtime `AIService`
// into the execution `Zone` when running heavy tasks.

// 2. Execute via ZenExecutor (ONLY valid path)
final response = await zenExecutor.execute(task);

// 3. Handle result
print(response.text);
```

### Available AI Tasks

```dart
// Text Generation
TextGenerationAiTask(
  prompt: 'Your prompt',
  model: 'gemini-pro',
  aiService: aiService,
)

// Embeddings
EmbeddingsAiTask(
  texts: ['text1', 'text2'],
  model: 'textembedding-gecko',
  aiService: aiService,
)

// Classification
ClassificationAiTask(
  text: 'Your text',
  model: 'gemini-pro',
  labels: ['positive', 'negative'],
  aiService: aiService,
)
```

All tasks declare `weight: heavy` and `latency: slow` to ensure executor routes them to the jobs system.

---

## 🧠 **RATIONALE: Why Executor-Only?**

AI calls are **inherently expensive** and **must never block the event loop**.

### Characteristics of AI Operations

- **Network-bound**: Calls to GCP Vertex AI over HTTP
- **Latency-heavy**: Model inference can take seconds
- **Potentially long-running**: Complex prompts, large contexts
- **Billable**: GCP charges per token, including failures
- **Heavy weight**: Classified as `TaskWeight.heavy`

### What Direct Execution Would Cause

```dart
// ❌ This would BLOCK the event loop
final response = await aiService.textGeneration(request);
// Other HTTP requests cannot be processed during this call
// Server becomes unresponsive under load
```

### What Executor Guarantees

```dart
// ✅ Executor routes to jobs system (Cloud Run)
final response = await zenExecutor.execute(task);
// Event loop remains free
// Other requests continue processing
// AI work executes in isolated Cloud Run instance
```

### The executor provides:

1. **Isolation**: Heavy tasks route to jobs system, not event loop
2. **Cost Control**: Explicit weight classification (`heavy`)
3. **Cloud Run Safety**: Non-blocking execution guaranteed
4. **Budget Enforcement**: Pre-execution validation
5. **Deterministic Routing**: Task weight → execution path

**This restriction is intentional, non-negotiable, and enforced by design.**

See: [`/docs/execution_model.md`](../../docs/execution_model.md) for full architectural contract.

---

## 🎯 What This Package Is

`dartzen_ai` is an **AI infrastructure package**, not an AI product.

It provides:

- **AI Task Classes**: `TextGenerationAiTask`, `EmbeddingsAiTask`, `ClassificationAiTask`
- **Request/Response DTOs**: Structured data for AI operations
- **Internal Services**: `AIService`, `VertexAIClient`, `EchoAIService` (all `@internal`)
- **Budget Enforcement**: Pre-execution cost validation
- **Dev Mode**: Echo service for local development without GCP calls

This package is designed to run **inside a single event-loop server** without blocking it.

---

## 🧘🏻 What This Package Is NOT

`dartzen_ai` does **not**:

- Provide UI components
- Hide costs or billing behavior
- Execute AI logic synchronously
- Automatically parallelize requests
- Manage background workers
- Own domain-level AI features (summarization, QA, etc.)
- Allow direct service instantiation

It is infrastructure only, with executor-only execution enforced.

---

## ⚠️🔴 CRITICAL: BILLABLE SERVICE

### This package makes REAL, BILLABLE API calls to GCP Vertex AI / Gemini.

You **will be charged** for every request, including failures.

Approximate costs (subject to change):

- Text generation: ~$0.0001 / 1K input tokens + ~$0.0002 / 1K output tokens
- Embeddings: ~$0.00002 / 1K tokens
- Classification: model-dependent

### Mandatory Safeguards

Before production use:

1. Set **monthly budget limits**
2. Monitor usage in GCP Console
3. Use Echo service in dev/staging
4. Store credentials server-side only
5. Plan credential rotation

By default, requests are **blocked** when the monthly limit is exceeded.

---

## 🏗 Architecture

### Task-Based Execution (Public API)

- **TextGenerationAiTask**: Executes text generation via ZenExecutor
- **EmbeddingsAiTask**: Executes embeddings generation via ZenExecutor
- **ClassificationAiTask**: Executes classification via ZenExecutor

All tasks:

- Extend `ZenTask<T>`
- Declare `weight: heavy`, `latency: slow`, `retryable: true`
- Execute only via `ZenExecutor.execute(task)`

### Internal Services (Not Public)

- **AIService**: High-level orchestration. Marked `@internal`.
- **VertexAIClient**: Low-level HTTP client. Marked `@internal`.
- **AIBudgetEnforcer**: Budget enforcement. Internal implementation.
- **EchoAIService**: Dev-mode mock. Marked `@internal`.
- **AIClient**: Client stub. Marked `@internal` (client-side AI not supported).

All services are injected via DI, never instantiated by user code.

---

## 🧪 Dev Mode: Echo Service

The Echo service mirrors real response structures without billing.

In dev mode, tasks use `EchoAIService` instead of production `AIService`:

```dart
// Dev mode configuration
final config = AIServiceConfig.dev();
const echoService = EchoAIService(); // Internal, for task injection

// Create task (dev mode uses Echo service provided by the executor worker)
final task = TextGenerationAiTask(
  prompt: 'Hello world',
  model: 'gemini-pro',
);
// The executor worker will provide `EchoAIService` at runtime; do not
// construct tasks with service instances embedded.

// Execute via ZenExecutor
final response = await zenExecutor.execute(task);
// Response: TextGenerationResponse(text: 'Echo: Hello world', ...)
```

Use this for:

- Local development
- CI tests
- Budget-free experimentation

---

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_ai:
    path: ../dartzen_ai
  dartzen_executor:
    path: ../dartzen_executor
```

### External Usage

```yaml
dependencies:
  dartzen_ai: ^latest_version
  dartzen_executor: ^latest_version
```

## Cache-backed Usage Persistence

`dartzen_ai` persists monthly AI usage so the `AIBudgetEnforcer` can
enforce limits. The package ships a cache-backed store `CacheAIUsageStore`
which uses the `dartzen_cache` package for persistence (supports
in-memory and Memorystore/Redis backends).

Example wiring (server-side only):

```dart
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';

// Build a CacheClient (use memorystore config in production)
const cacheConfig = CacheConfig(); // or provide memorystoreHost/Port
final cache = CacheFactory.create(cacheConfig);

// Create the store and inject into the enforcer
final store = CacheAIUsageStore.withClient(cache);
final enforcer = AIBudgetEnforcer(usageTracker: store, config: budgetConfig);
```

## Cache-backed AIUsageStore Example

The package provides a `CacheAIUsageStore` implementation which persists
monthly usage counters to a `CacheClient` (for example a Redis-backed
`MemorystoreCache` in production) while keeping an in-memory synchronous
surface for low-latency reads. See the example in `example/cache_wiring_example.dart`
for a full wiring example. Minimal usage:

```dart
import 'package:dartzen_cache/dartzen_cache.dart';
import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';

final cache = InMemoryCache(); // use CacheFactory.create(config) in prod
final store = CacheAIUsageStore.withClient(cache);

// record usage (synchronous updates to memory, async flush to cache)
store.recordUsage('textGeneration', 1.25);

// read current in-memory values
final global = store.getGlobalUsage();
final textGen = store.getMethodUsage('textGeneration');

// reset counters and persist zeros
store.reset();

// close when shutting down
await store.close();
```

Prefer `InMemoryCache` for deterministic tests and local development; use
`CacheFactory.create` with a production `CacheConfig` for memorystore in CI/prod.

Notes:

- Keys are namespaced with `dartzen:ai:usage:<method>:YYYY-MM` so
  monthly counters expire automatically when using a TTL-capable backend.
- For production, configure `CacheConfig` to point to Memorystore/Redis.
- The `CacheAIUsageStore.connect` convenience factory builds the client
  from a `CacheConfig` and loads cached counters on startup.

---

## 🚀 Complete Usage Example

```dart
import 'package:dartzen_ai/dartzen_ai.dart';
import 'package:dartzen_executor/dartzen_executor.dart';
// Internal imports for service setup (server-side DI)
import 'package:dartzen_ai/src/server/ai_service.dart';
import 'package:dartzen_ai/src/server/vertex_ai_client.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';

// ============================================================================
// SERVER-SIDE SETUP (Internal, DI Container)
// ============================================================================

final config = AIServiceConfig(
  projectId: 'my-project',
  region: 'us-central1',
  credentialsJson: credentialsJson,
  budgetConfig: AIBudgetConfig(monthlyLimit: 100.0),
);

final aiService = AIService(
  client: VertexAIClient(config: config),
  budgetEnforcer: AIBudgetEnforcer(
    config: config.budgetConfig,
    usageTracker: myUsageTracker,
  ),
);

final executor = ZenExecutor(
  config: ZenExecutorConfig(
    queueId: 'ai-task-queue',
    serviceUrl: 'https://my-service.run.app',
  ),
);

// ============================================================================
// TASK CREATION AND EXECUTION (User Code)
// ============================================================================

// Create AI task
final task = TextGenerationAiTask(
  prompt: 'Write a haiku about coding',
  model: 'gemini-pro',
  aiService: aiService, // Injected from DI
);

// Execute via ZenExecutor (ONLY valid path)
try {
  final response = await executor.execute(task);
  print(response.text);
  print('Tokens: ${response.usage?.totalTokens}');
} catch (e) {
  print('Error: $e');
}
```

---

## 🧩 Extending AI Capabilities

`dartzen_ai` does not define domain features. You are expected to create your own task subclasses.

### Example: Custom Summarization Task

```dart
class SummarizationAiTask extends ZenTask<String> {
  final String text;
  final AIService aiService;

  SummarizationAiTask({required this.text, required this.aiService});

  @override
  ZenTaskDescriptor get descriptor => const ZenTaskDescriptor(
        weight: TaskWeight.heavy,
        latency: Latency.slow,
        retryable: true,
      );

  @override
  Future<String> execute() async {
    final request = TextGenerationRequest(
      prompt: 'Summarize the following:\n\n$text',
      model: 'gemini-pro',
    );

    final result = await aiService.textGeneration(request);

    return result.fold(
      (response) => response.text,
      (error) => throw error,
    );
  }
}

// Usage
final task = SummarizationAiTask(text: longText, aiService: aiService);
final summary = await executor.execute(task);
```

This keeps:

- AI infrastructure reusable
- Domain logic explicit
- Execution behavior predictable

---

## 📱 Client-Side Usage

**Client-side direct AI execution is NOT SUPPORTED.**

This is intentional:

1. **Security**: GCP credentials must never be exposed to clients
2. **Cost Control**: Budget enforcement happens server-side only
3. **Event Loop Safety**: AI calls would block UI thread
4. **Billing**: Direct client calls would bypass tracking

### ✅ Correct Client-Server Flow

1. **Client**: Sends HTTP request to DartZen server via `ZenClient`
2. **Server**: Receives request via HTTP endpoint
3. **Server**: Creates AI task (e.g., `TextGenerationAiTask`)
4. **Server**: Executes task via `ZenExecutor`
5. **Executor**: Routes task to jobs system (heavy weight)
6. **Server**: Returns response to client via HTTP

Client never executes AI directly. All AI work is server-side, executor-routed.

---

## ❗ Error Model

All task execution failures throw typed exceptions:

- `AIBudgetExceededError`
- `AIQuotaExceededError`
- `AIInvalidRequestError`
- `AIServiceUnavailableError`
- `AIAuthenticationError`
- `AICancelledError`

No raw exceptions leak across package boundaries.

---

## 📊 Telemetry

Optional server-side telemetry events (emitted by `AIService`, internal):

- `ai.text_generation.success|failure`
- `ai.embeddings.success|failure`
- `ai.classification.success|failure`
- `ai.budget.exceeded`

Telemetry is **opt-in** and explicitly wired.

---

## 🔒 Enforcement Summary

| Mechanism                   | What                            | How                                       |
| --------------------------- | ------------------------------- | ----------------------------------------- |
| **`@internal` annotations** | Services cannot be instantiated | Analyzer error                            |
| **Package exports**         | Services not exported           | Import fails                              |
| **Task-only API**           | Only tasks are public           | No alternative execution path             |
| **Descriptor enforcement**  | Tasks declare weight            | Executor routes by weight                 |
| **Runtime assertion**       | Debug-mode guard                | Fails if `task.execute()` called directly |

---

## 🛡 Stability

This package is evolving.

Breaking changes are expected until the execution model, auth, and budget semantics are finalized.

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
