// ignore_for_file: avoid_print, comment_references
/// Flutter client example explaining executor-only execution model.
///
/// ## ❌ IMPORTANT: Client-side AI execution is NOT POSSIBLE
///
/// This example demonstrates that client-side code CANNOT execute AI operations
/// directly. All AI work must be executed server-side via [ZenTask] subclasses
/// routed through [ZenExecutor].
///
/// ## Why Client-Side Direct Execution is Forbidden
///
/// 1. **Security**: GCP credentials must never be exposed to clients
/// 2. **Cost Control**: Budget enforcement happens server-side only
/// 3. **Event Loop Safety**: AI calls are heavy/slow and would block UI
/// 4. **Billing**: Direct client calls would bypass server-side tracking
///
/// ## ✅ Correct Client-Server Flow
///
/// 1. **Client**: Sends request to DartZen server via [ZenClient]
/// 2. **Server**: Receives request via HTTP endpoint
/// 3. **Server**: Creates AI task (e.g., [TextGenerationAiTask])
/// 4. **Server**: Executes task via [ZenExecutor]
/// 5. **Executor**: Routes task to jobs system (heavy weight)
/// 6. **Server**: Returns response to client
///
/// ## Example Client Code (Hypothetical)
///
/// ```dart
/// // Client sends HTTP request to server endpoint
/// final zenClient = ZenClient(baseUrl: 'https://myapp.run.app');
///
/// final response = await zenClient.post(
///   '/api/ai/generate-text',
///   body: {
///     'prompt': 'Write a haiku',
///     'model': 'gemini-pro',
///   },
/// );
/// ```
///
/// ## Example Server Endpoint (Hypothetical)
///
/// ```dart
/// // Server endpoint handler
/// @Post('/api/ai/generate-text')
/// Future<Response> generateText(Request request) async {
///   final body = await request.json();
///
///   // Create AI task (server-side only)
///   final task = TextGenerationAiTask(
///     prompt: body['prompt'],
///     model: body['model'],
///     aiService: injectedAIService, // DI
///   );
///
///   // Execute via ZenExecutor (ONLY valid path)
///   final result = await zenExecutor.execute(task);
///
///   return Response.json(result);
/// }
/// ```
///
/// ## Summary
///
/// - ❌ Clients cannot instantiate [AIClient] (marked @internal)
/// - ❌ Clients cannot call AI services directly
/// - ✅ Clients send HTTP requests to server endpoints
/// - ✅ Server creates tasks and executes via [ZenExecutor]
/// - ✅ Server returns results to client via HTTP responses
void main() {
  print('=== DartZen AI Client Example ===\n');
  print('❌ Client-side direct AI execution is NOT SUPPORTED.\n');
  print('This is intentional and enforced by design:\n');
  print('1. AIClient is marked @internal (analyzer error if used)');
  print('2. GCP credentials are server-side only');
  print('3. AI calls are heavy/slow (must route via executor)');
  print('4. Budget enforcement is server-side only\n');
  print('✅ Correct approach:');
  print('   - Client sends HTTP request to server endpoint');
  print('   - Server creates AI task (TextGenerationAiTask, etc.)');
  print('   - Server executes task via ZenExecutor');
  print('   - Server returns response to client\n');
  print('See server_example.dart for task-based execution.\n');
  print('\n=== Example Complete ===');
}
