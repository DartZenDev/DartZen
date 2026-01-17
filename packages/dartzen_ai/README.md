# DartZen AI

[![pub package](https://img.shields.io/pub/v/dartzen_ai.svg)](https://pub.dev/packages/dartzen_ai)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

> 🚧 **NOT PRODUCTION READY** — authentication and credential rotation are not finalized.

**Vertex AI / Gemini integration for DartZen, designed for non-blocking server runtimes.**

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 What This Package Is

`dartzen_ai` is an **AI infrastructure package**, not an AI product.

It provides:

- A **server-side AI service** for GCP Vertex AI / Gemini
- Explicit **budget enforcement** and usage tracking
- A **Flutter client** with cancellable requests
- A **dev-mode Echo service** for local development
- Clear boundaries aligned with DartZen’s execution model

This package is designed to run **inside a single event-loop server** without blocking it.

## 🧠 Execution Model Compatibility

AI calls are **inherently expensive**:

- Network-bound
- Latency-heavy
- Potentially long-running
- Billable

Because DartZen servers run in a **single event-loop runtime**, this package follows strict rules:

- No synchronous I/O
- No CPU-heavy processing on the request path
- All AI calls are **awaited async operations**
- Cancellation is first-class
- Budget enforcement happens **before** remote calls

This package assumes the execution model defined in:

**`/docs/execution-model.md`**

If an AI workflow blocks the event loop, it is considered a defect.

## 🧘🏻 What This Package Is NOT

`dartzen_ai` does **not**:

- Provide UI components
- Hide costs or billing behavior
- Execute AI logic synchronously
- Automatically parallelize requests
- Manage background workers
- Own domain-level AI features (summarization, QA, etc.)

It is infrastructure only.

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
4. Use `CancelToken` for user-driven aborts
5. Store credentials server-side only
6. Plan credential rotation

By default, requests are **blocked** when the monthly limit is exceeded.

## 🏗 Architecture

### Server Components

- **AIService**: High-level orchestration layer. Performs validation, budget checks, and delegation.
- **VertexAIClient**: Low-level HTTP client for Vertex AI / Gemini REST APIs.
- **AIBudgetEnforcer**: Enforces per-method and global monthly limits.
- **EchoAIService**: Dev-mode service returning deterministic mock responses without GCP calls.
- **Telemetry Hooks**: Optional usage and cost tracking.

### Client Components

- **AIClient**: Thin Flutter client that talks to your server.
- **CancelToken**: Allows aborting long-running AI requests.

There are **no widgets** and no UI assumptions.

## 🧪 Dev Mode: Echo Service

The Echo service mirrors real response structures without billing:

```dart
final echoService = EchoAIService();

final result = await echoService.textGeneration(
  TextGenerationRequest(
    prompt: 'Hello world',
    model: 'gemini-pro',
  ),
);

// Text: "Echo: Hello world"
```

Use this for:

- Local development
- CI tests
- Budget-free experimentation

## 📦 Installation

### In a Melos Workspace

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_ai:
    path: ../dartzen_ai
```

### External Usage

```yaml
dependencies:
  dartzen_ai: ^latest_version
```

---

## 🚀 Server-Side Usage

### Production Setup (Conceptual)

```dart
final config = AIServiceConfig(
  projectId: 'my-project',
  region: 'us-central1',
  credentialsJson: credentialsJson,
  budgetConfig: AIBudgetConfig(
    monthlyLimit: 100.0,
  ),
);

final service = AIService(
  client: VertexAIClient(config: config),
  budgetEnforcer: AIBudgetEnforcer(
    config: config.budgetConfig,
    usageTracker: FirestoreUsageTracker(),
  ),
);
```

All calls are async and cancellable.

## 🤖 Core API Methods

```dart
await service.textGeneration(request);
await service.embeddings(request);
await service.classification(request);
```

Each method:

- Validates input
- Checks budget
- Makes async network call
- Records usage
- Returns `ZenResult<T>`

## 📱 Client-Side Usage

```dart
final aiClient = AIClient(zenClient: myZenClient);

final result = await aiClient.textGeneration(
  prompt: 'Write a haiku',
  model: 'gemini-pro',
);

result.when(
  success: (r) => print(r.text),
  failure: (e) => print(e.message),
);
```

### Cancellation

```dart
final token = CancelToken();

final future = aiClient.textGeneration(
  prompt: 'Long task',
  model: 'gemini-pro',
  cancelToken: token,
);

token.cancel();
```

## 🧩 Extending AI Capabilities

`dartzen_ai` does not define domain features.

You are expected to wrap it.

### Server-Side Example

```dart
class SummarizationService {
  final AIService ai;

  Future<ZenResult<String>> summarize(String text) async {
    final result = await ai.textGeneration(
      TextGenerationRequest(
        prompt: 'Summarize:\n\n$text',
        model: 'gemini-pro',
      ),
    );
    return result.map((r) => r.text);
  }
}
```

This keeps:

- AI infrastructure reusable
- Domain logic explicit
- Execution behavior predictable

## ❗ Error Model

All methods return `ZenResult<T>`.

Notable errors:

- `AIBudgetExceededError`
- `AIQuotaExceededError`
- `AIInvalidRequestError`
- `AIServiceUnavailableError`
- `AIAuthenticationError`
- `AICancelledError`

No raw exceptions leak across package boundaries.

## 📊 Telemetry

Optional server-side telemetry events:

- `ai.text_generation.success|failure`
- `ai.embeddings.success|failure`
- `ai.classification.success|failure`
- `ai.budget.exceeded`

Telemetry is **opt-in** and explicitly wired.

## 🛡 Stability

This package is evolving.

Breaking changes are expected until the execution model, auth, and budget semantics are finalized.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
