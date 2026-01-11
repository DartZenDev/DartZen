/// DartZen AI - GCP Vertex AI / Gemini integration for DartZen applications.
///
/// This package provides AI capabilities through Google Cloud Platform's
/// Vertex AI and Gemini services. It includes both server-side and client-side
/// components with dev mode Echo service for local testing.
///
/// ## Features
///
/// - **Server-side AI Service**: Handles all Vertex AI / Gemini API calls
/// - **Dev Mode Echo Service**: Mock responses for local development
/// - **Budget Enforcement**: Per-method and global monthly limits
/// - **Flutter Client**: Cancellable requests with offline support
/// - **Telemetry Integration**: Usage tracking and analytics
/// - **Extensible**: Add custom methods by wrapping client calls
///
/// ## Optionality
///
/// This package is **fully optional**. The DartZen system functions completely
/// without `dartzen_ai`. Package activation is controlled by configuration.
///
/// ## Security
///
/// GCP credentials are stored and used **server-side only**. The Flutter client
/// never has direct access to API keys or credentials.
///
/// ## Usage
///
/// ### Server-side
///
/// ```dart
/// import 'package:dartzen_ai/dartzen_ai.dart';
///
/// // Production configuration
/// final config = AIServiceConfig(
///   projectId: 'my-project',
///   region: 'us-central1',
///   credentialsJson: await loadCredentials(),
///   budgetConfig: AIBudgetConfig(monthlyLimit: 100.0),
/// );
///
/// final client = VertexAIClient(config: config);
/// final budgetEnforcer = AIBudgetEnforcer(
///   config: config.budgetConfig,
///   usageTracker: AIUsageTracker(),
/// );
/// final service = AIService(
///   client: client,
///   budgetEnforcer: budgetEnforcer,
/// );
///
/// final request = TextGenerationRequest(
///   prompt: 'Write a haiku',
///   model: 'gemini-pro',
/// );
///
/// final result = await service.textGeneration(request);
/// ```
///
/// ### Client-side
///
/// ```dart
/// import 'package:dartzen_ai/dartzen_ai.dart';
///
/// final aiClient = AIClient(zenClient: myZenClient);
///
/// final result = await aiClient.textGeneration(
///   prompt: 'Write a haiku',
///   model: 'gemini-pro',
/// );
/// ```
///
/// ### Dev Mode
///
/// ```dart
/// // Dev mode configuration (no credentials required)
/// final config = AIServiceConfig.dev();
/// final echoService = EchoAIService();
///
/// final result = await echoService.textGeneration(request);
/// // Returns: TextGenerationResponse(text: 'Echo: Write a haiku', ...)
/// ```
library;

export 'src/client/ai_client.dart';
export 'src/client/cancel_token.dart';
export 'src/errors/ai_error.dart';
export 'src/l10n/ai_messages.dart';
export 'src/models/ai_config.dart';
export 'src/models/ai_request.dart';
export 'src/models/ai_response.dart';
export 'src/server/ai_budget_enforcer.dart';
export 'src/server/ai_service.dart';
export 'src/server/echo_ai_service.dart';
