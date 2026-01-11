# DartZen AI

[![pub package](https://img.shields.io/pub/v/dartzen_ai.svg)](https://pub.dev/packages/dartzen_ai)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

> 🚧 NOT PRODUCTION READY — Authentication and credential rotation are incomplete.

**GCP Vertex AI / Gemini integration for DartZen applications.**

---

## ⚠️🔴 **CRITICAL: BILLABLE SERVICE**

### **This package makes REAL, BILLABLE API calls to Google Cloud Platform Vertex AI / Gemini services.**

**YOU WILL BE CHARGED** for every API call, including failed requests. Usage is tracked in USD. Example costs:

- Text generation: ~$0.0001 per 1K tokens (input) + $0.0002 per 1K tokens (output)
- Embeddings: ~$0.00002 per 1K tokens
- Classification: Variable based on model

**Before using in production:**

1. ⚠️ This package cannot perform real Vertex AI calls until authentication is implemented. See "Missing features" below.
2. ✅ Set realistic monthly limits via `AIBudgetConfig.monthlyLimit`
3. ✅ Monitor spending via Google Cloud Console
4. ✅ Test thoroughly with **Echo service** in dev/staging
5. ✅ Use **CancelToken** to abort expensive requests if needed
6. ✅ Rotate GCP credentials regularly once auth is implemented

**Default behavior:** Budget enforcer blocks requests when monthly limit is exceeded. This is your primary defense against runaway costs.

---

This package provides AI capabilities through Google Cloud Platform's Vertex AI and Gemini services, with both server-side and client-side components, dev mode Echo service for local testing, and budget enforcement.

## Missing features / Known limitations

- Authentication: service-account-based access token retrieval is not yet implemented. The package currently uses a placeholder token in `VertexAIClient`.
- Credential rotation: no automatic rotation for long-running services.
- Production-grade retry/backoff: current retry is basic and lacks jitter and Retry-After handling.
- Telemetry naming: event names must follow dot-notation alphanumeric rules.
- Cost calculation: billing logic is currently in `AIUsage` (work planned to move into enforcer).

Please refer to the TODOs in the repository for planned work and contribute if you can.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 🎯 Purpose

- Integrate GCP Vertex AI / Gemini into DartZen applications
- Provide server-side AI service with budget enforcement
- Offer Flutter client with cancellable requests and offline support
- Enable local development with Echo service (no GCP required)
- Track usage via telemetry integration

## ⚠️ Important Notices

### Optionality

This package is **fully optional**. The DartZen system functions completely without `dartzen_ai`. Package activation is controlled by configuration/environment. Absence of this package does not affect core workflows.

### GCP Billing Risk

> **WARNING**: This package makes real API calls to Vertex AI / Gemini, which **incur costs**. Budget enforcement is implemented server-side to prevent unexpected expenses. Configure monthly limits carefully before deploying to production.

### Security

> **CRITICAL**: GCP credentials are stored and used **server-side only**. The Flutter client never has direct access to API keys or credentials. Implement secure credential storage and rotation policies in production. Server validates JWT and request ownership before querying Vertex AI.

## 🏗 Architecture

### Server Components

- **AIService**: Main service handling all Vertex AI / Gemini API calls
- **EchoAIService**: Dev mode service returning mock responses
- **VertexAIClient**: Low-level REST API client
- **AIBudgetEnforcer**: Budget tracking and enforcement
- **Retry Logic**: Exponential backoff for failed requests
- **Telemetry**: Optional usage tracking

### Client Components

- **AIClient**: Flutter client for server communication
- **CancelToken**: Request cancellation support
- **Offline Mode**: Automatic retry on reconnection
- **No UI Widgets**: Pure API client (UI handled by separate packages)

### Dev Mode Echo Service

The Echo service provides **structurally identical** responses to Vertex AI without making GCP calls:

```dart
// Input
textGeneration("Hello world")

// Output
TextGenerationResponse(
  text: "Echo: Hello world",
  requestId: "echo_...",
  usage: AIUsage(inputTokens: 10, outputTokens: 20),
  metadata: {"mode": "echo", "model": "gemini-pro"}
)
```

Budget limits can be ignored in dev mode (configurable).

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

## 🚀 Usage

### Server-Side Setup

#### Production Configuration

```dart
import 'package:dartzen_ai/dartzen_ai.dart';

// Load GCP credentials (server-side only)
final credentialsJson = await File('service-account.json').readAsString();

final config = AIServiceConfig(
  projectId: 'my-gcp-project',
  region: 'us-central1',
  credentialsJson: credentialsJson,
  budgetConfig: AIBudgetConfig(
    monthlyLimit: 100.0,  // $100 USD per month
    textGenerationLimit: 50.0,  // $50 USD for text generation
    embeddingsLimit: 30.0,  // $30 USD for embeddings
    classificationLimit: 20.0,  // $20 USD for classification
  ),
);

final client = VertexAIClient(config: config);
final budgetEnforcer = AIBudgetEnforcer(
  config: config.budgetConfig,
  usageTracker: InMemoryUsageTracker(),  // Use Firestore in production
);

final service = AIService(
  client: client,
  budgetEnforcer: budgetEnforcer,
  telemetryClient: myTelemetryClient,  // Optional
);
```

#### Dev Mode Configuration

```dart
// No credentials required
final config = AIServiceConfig.dev();
final echoService = EchoAIService();

final request = TextGenerationRequest(
  prompt: 'Write a haiku',
  model: 'gemini-pro',
);

final result = await echoService.textGeneration(request);
// Returns: TextGenerationResponse(text: 'Echo: Write a haiku', ...)
```

### Server-Side API Methods

```dart
// Text generation
final textRequest = TextGenerationRequest(
  prompt: 'Explain quantum computing',
  model: 'gemini-pro',
  config: AIModelConfig(temperature: 0.7, maxTokens: 1024),
);
final textResult = await service.textGeneration(textRequest);

// Embeddings
final embeddingsRequest = EmbeddingsRequest(
  texts: ['Hello world', 'Goodbye world'],
  model: 'textembedding-gecko',
);
final embeddingsResult = await service.embeddings(embeddingsRequest);

// Classification
final classificationRequest = ClassificationRequest(
  text: 'This product is amazing!',
  model: 'gemini-pro',
  labels: ['positive', 'negative', 'neutral'],
);
final classificationResult = await service.classification(classificationRequest);
```

### Client-Side Usage

```dart
import 'package:dartzen_ai/dartzen_ai.dart';

final aiClient = AIClient(zenClient: myZenClient);

// Text generation
final result = await aiClient.textGeneration(
  prompt: 'Write a motivational message',
  model: 'gemini-pro',
);

result.when(
  success: (response) => print(response.text),
  failure: (error) => print('Error: ${error.message}'),
);

// Embeddings
final embeddingsResult = await aiClient.embeddings(
  texts: ['Sample text'],
  model: 'textembedding-gecko',
);

// Classification
final classificationResult = await aiClient.classification(
  text: 'I feel happy',
  model: 'gemini-pro',
  labels: ['happy', 'sad', 'neutral'],
);

// Cancellable request
final token = CancelToken();
final future = aiClient.textGeneration(
  prompt: 'Long running task',
  model: 'gemini-pro',
  cancelToken: token,
);
// Later...
token.cancel();
```

### Extensibility: Custom Methods

Users can add custom methods by wrapping client calls:

```dart
extension AIClientExtensions on AIClient {
  Future<ZenResult<TextGenerationResponse>> summarization(String text) {
    return textGeneration(
      prompt: 'Summarize the following text:\n\n$text',
      model: 'gemini-pro',
      config: AIModelConfig(temperature: 0.3, maxTokens: 256),
    );
  }

  Future<ZenResult<TextGenerationResponse>> questionAnswering({
    required String context,
    required String question,
  }) {
    return textGeneration(
      prompt: 'Context: $context\n\nQuestion: $question\n\nAnswer:',
      model: 'gemini-pro',
    );
  }
}
```

## 💰 Budget Enforcement

Budget limits are enforced **server-side** before making API calls:

- **Per-method limits**: Separate budgets for text generation, embeddings, and classification
- **Global monthly limit**: Total spending across all methods
- **Automatic tracking**: Usage recorded after each successful request
- **Dev mode**: Budget limits can be ignored (configurable)

When budget is exceeded, requests fail with `AIBudgetExceededError`.

## 🔒 Security Considerations

1. **Server-Only Credentials**: GCP credentials never leave the server
2. **JWT Validation**: Server validates request ownership before API calls
3. **Secure Storage**: Use GCP Secret Manager or equivalent for credentials
4. **Credential Rotation**: Implement regular rotation policies
5. **Budget Limits**: Prevent runaway costs with enforced limits
6. **Telemetry**: Detect anomalous usage patterns

## ❗ Error Handling

All operations return `ZenResult<T>` with semantic error codes:

- `AIBudgetExceededError`: Budget limit reached
- `AIQuotaExceededError`: GCP quota exceeded
- `AIInvalidRequestError`: Invalid parameters
- `AIServiceUnavailableError`: Service down (includes retry-after)
- `AIAuthenticationError`: Credential issues
- `AICancelledError`: Request cancelled by user

```dart
final result = await aiClient.textGeneration(
  prompt: 'Hello',
  model: 'gemini-pro',
);

result.when(
  success: (response) {
    print('Generated: ${response.text}');
    print('Tokens: ${response.usage?.totalTokens}');
    print('Tokens: ${response.usage?.totalTokens}');
  },
  failure: (error) {
    if (error is AIBudgetExceededError) {
      print('Budget exceeded: ${error.current}/${error.limit}');
    } else if (error is AIServiceUnavailableError) {
      print('Retry after: ${error.retryAfter}');
    } else {
      print('Error: ${error.message}');
    }
  },
);
```

## 📊 Telemetry Integration

Optional telemetry tracking (server-side only):

- `ai.text_generation.success` / `ai.text_generation.failure`
- `ai.embeddings.success` / `ai.embeddings.failure`
- `ai.classification.success` / `ai.classification.failure`
- `ai.*.budget_exceeded`

Telemetry for custom client methods is optional and user-implemented.

## 🧪 Testing

The Echo service enables testing without GCP:

```dart
void main() {
  test('AI text generation', () async {
    final echoService = EchoAIService();
    final request = TextGenerationRequest(
      prompt: 'Test prompt',
      model: 'gemini-pro',
    );

    final result = await echoService.textGeneration(request);

    expect(result.isSuccess, true);
    expect(result.value!.text, 'Echo: Test prompt');
  });
}
```

## 🎨 Building Custom AI Features

**`dartzen_ai` is infrastructure, not a product.** It provides the foundation for building domain-specific AI capabilities.

### Extending on the Server

Wrap `AIService` methods to add your own logic:

```dart
// domain/summarization_service.dart
class SummarizationService {
  final AIService aiService;
  SummarizationService({required this.aiService});

  Future<ZenResult<String>> summarize(String text) async {
    final request = TextGenerationRequest(
      prompt: 'Summarize in 3 sentences:\n\n$text',
      model: 'gemini-pro',
    );

    final result = await aiService.textGeneration(request);
    return result.fold(
      ok: (response) => ZenResult.ok(response.text),
      err: (error) => ZenResult.err(error),
    );
  }
}
```

### Custom Client Methods

Extend `AIClient` on the Flutter side:

```dart
// Add this to your service/ai_extension.dart
extension AIClientExtension on AIClient {
  Future<ZenResult<String>> summarize(
    String text, {
    CancelToken? cancelToken,
  }) {
    return textGeneration(
      prompt: 'Summarize:\n\n$text',
      model: 'gemini-pro',
      cancelToken: cancelToken,
    ).then((result) => result.fold(
      ok: (r) => ZenResult.ok(r.text),
      err: (e) => ZenResult.err(e),
    ));
  }
}
```

### Multi-Step Pipelines

Chain methods for complex workflows:

```dart
// QA service combining embeddings → classification
class QAService {
  final AIService aiService;

  Future<ZenResult<String>> answer(String question, List<String> documents) async {
    // Step 1: Find most relevant document
    final embReq = EmbeddingsRequest(
      texts: [question, ...documents],
      model: 'textembedding-gecko',
    );

    final embResult = await aiService.embeddings(embReq);
    // ... similarity matching logic

    // Step 2: Generate answer from best doc
    final textReq = TextGenerationRequest(
      prompt: 'Answer: $question\nContext: $bestDoc',
      model: 'gemini-pro',
    );

    return (await aiService.textGeneration(textReq)).fold(
      ok: (r) => ZenResult.ok(r.text),
      err: (e) => ZenResult.err(e),
    );
  }
}
```

## 🛡️ Stability Guarantees

This package is in early development (0.0.1). Expect breaking changes as the DartZen ecosystem evolves.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
