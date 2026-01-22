/// DartZen AI - GCP Vertex AI / Gemini integration for DartZen applications.
///
/// This package provides AI capabilities through Google Cloud Platform's
/// Vertex AI and Gemini services. All AI operations MUST be executed via
/// ZenExecutor using task-based execution.
///
/// ## ❌ Forbidden Usage
///
/// Do NOT instantiate AI services directly:
/// ```dart
/// // ❌ WRONG - This will fail with analyzer error
/// final ai = AIService(...);
/// final response = await ai.textGeneration(...);
/// ```
///
/// Do NOT call client directly:
/// ```dart
/// // ❌ WRONG - This will fail with analyzer error
/// final client = AIClient(...);
/// final response = await client.textGeneration(...);
/// ```
///
/// Do NOT use low-level HTTP client:
/// ```dart
/// // ❌ WRONG - This will fail with analyzer error
/// final vertexAI = VertexAIClient(...);
/// final response = await vertexAI.generateText(...);
/// ```
///
/// ## ✅ Correct Usage
///
/// All AI operations MUST be executed via ZenExecutor:
///
/// ```dart
/// import 'package:dartzen_ai/dartzen_ai.dart';
/// import 'package:dartzen_executor/dartzen_executor.dart';
///
/// // Create AI service (server-side, internal use)
/// final aiService = AIService(
///   client: vertexAIClient,
///   budgetEnforcer: budgetEnforcer,
/// );
///
/// // Create task with injected service
/// final task = TextGenerationAiTask(
///   prompt: 'Write a haiku about coding',
///   model: 'gemini-pro',
///   aiService: aiService,
/// );
///
/// // Execute via ZenExecutor (ONLY valid path)
/// final result = await zenExecutor.execute(task);
/// ```
///
/// ## 🧠 Rationale
///
/// AI calls are **inherently expensive**:
/// - Network-bound (GCP Vertex AI)
/// - Latency-heavy (model inference)
/// - Potentially long-running
/// - Billable (per token)
///
/// Direct execution can block the event loop and degrade server performance.
/// The executor guarantees:
/// - Isolation (jobs system routing)
/// - Cost control (explicit weight classification)
/// - Cloud Run safety (non-blocking execution)
///
/// This restriction is **intentional and non-negotiable** for DartZen servers.
///
/// ## Features
///
/// - **Task-based Execution**: AI tasks extend ZenTask with heavy weight
/// - **Budget Enforcement**: Per-method and global monthly limits
/// - **Dev Mode Echo Service**: Mock responses for local development
/// - **Telemetry Integration**: Usage tracking and analytics
///
/// ## Optionality
///
/// This package is **fully optional**. The DartZen system functions completely
/// without dartzen_ai. Package activation is controlled by configuration.
///
/// ## Security
///
/// GCP credentials are stored and used **server-side only**. Clients
/// never have direct access to API keys or credentials.
library;

// Utilities (public API)
export 'src/client/cancel_token.dart';
// Error types (public API)
export 'src/errors/ai_error.dart';
// Localization (public API)
export 'src/l10n/ai_messages.dart';
// Request/Response DTOs (public API)
export 'src/models/ai_config.dart';
export 'src/models/ai_request.dart';
export 'src/models/ai_response.dart';
// Task classes (public API - executor-only execution)
export 'src/tasks/classification_ai_task.dart';
export 'src/tasks/embeddings_ai_task.dart';
export 'src/tasks/text_generation_ai_task.dart';

// Internal services (NOT exported - marked @internal)
// - AIService (use via tasks only)
// - AIClient (use via tasks only)
// - VertexAIClient (use via tasks only)
// - EchoAIService (use via tasks only)
// - AIBudgetEnforcer (internal implementation detail)
