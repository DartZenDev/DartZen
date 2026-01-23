import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';

import 'job_context.dart';

/// Base class for serializable heavy tasks that use Zone service injection.
///
/// [AggregationTask] enforces a strict separation between task data (which must
/// be JSON-serializable) and runtime services (which are injected via Zone).
///
/// ## Design Principles
///
/// 1. **Serialization Contract**: Task payloads must be pure data—no closures,
///    no runtime objects, no captured dependencies. This ensures tasks can be:
///    - Persisted to Firestore
///    - Rehydrated in different processes
///    - Dispatched to Cloud Run workers
///
/// 2. **Zone Service Injection**: Runtime dependencies (AI services, HTTP
///    clients, loggers) are injected via Dart's `Zone` API during execution.
///    Tasks access these services through `Zone.current[key]`, not through
///    constructor parameters or captured closures.
///
/// 3. **Deterministic Execution**: Given the same payload and zone services,
///    a task should produce the same result. This makes tasks testable,
///    debuggable, and retry-safe.
///
/// ## Usage Example
///
/// ```dart
/// class DataAggregationTask extends AggregationTask {
///   final String dataSourceId;
///   final List<String> filters;
///
///   // Constructor accepts only JSON-serializable data
///   DataAggregationTask({
///     required this.dataSourceId,
///     required this.filters,
///   });
///
///   @override
///   Map<String, dynamic> toPayload() => {
///     'dataSourceId': dataSourceId,
///     'filters': filters,
///   };
///
///   // Factory for rehydration from stored payload
///   factory DataAggregationTask.fromPayload(Map<String, dynamic> payload) {
///     return DataAggregationTask(
///       dataSourceId: payload['dataSourceId'] as String,
///       filters: List<String>.from(payload['filters'] as List),
///     );
///   }
///
///   @override
///   Future<ZenResult<Map<String, dynamic>>> execute(JobContext context) async {
///     // Access Zone services without capturing them in payload
///     final aiService = Zone.current['dartzen.ai.service'] as AIService?;
///     final logger = Zone.current['dartzen.logger'] as Logger?;
///
///     logger?.info('Starting aggregation for $dataSourceId');
///
///     try {
///       // Use services for computation
///       final result = await aiService?.analyzeData(dataSourceId, filters);
///       return ZenResult.ok({'data': result});
///     } catch (e, s) {
///       logger?.error('Aggregation failed', error: e, stackTrace: s);
///       return ZenResult.err(
///         ZenUnknownError('Aggregation failed: $e', stackTrace: s),
///       );
///     }
///   }
/// }
/// ```
///
/// ## Available Zone Services
///
/// When running inside an executor, tasks can access:
/// - `Zone.current['dartzen.executor']` (bool): True if in executor context
/// - `Zone.current['dartzen.ai.service']`: AI service for model inference
/// - `Zone.current['dartzen.http.client']`: HTTP client for network requests
/// - `Zone.current['dartzen.logger']`: Logger for structured logging
/// - `Zone.current['dartzen.storage']`: Storage service (optional)
///
/// Always check for null before using services, as they may not be available
/// in all execution contexts (e.g., unit tests without zone setup).
///
/// ## Testing
///
/// Tasks can be tested independently by:
/// 1. Creating test payloads
/// 2. Mocking zone services
/// 3. Executing in a test zone
///
/// ```dart
/// test('DataAggregationTask processes data correctly', () async {
///   final task = DataAggregationTask(
///     dataSourceId: 'test-source',
///     filters: ['filter1'],
///   );
///
///   // Create mock services
///   final mockAI = MockAIService();
///   when(() => mockAI.analyzeData(any(), any()))
///       .thenAnswer((_) async => {'result': 'test'});
///
///   // Execute in zone with mock services
///   final result = await runZoned(
///     () => task.execute(testContext),
///     zoneValues: {
///       'dartzen.executor': true,
///       'dartzen.ai.service': mockAI,
///     },
///   );
///
///   expect(result.isSuccess, isTrue);
/// });
/// ```
///
/// See also:
/// - [docs/execution_model.md] for zone service contract
/// - [JobContext] for execution context details
abstract class AggregationTask<T> {
  /// Serializes this task to a JSON-safe payload for persistence.
  ///
  /// The returned map must contain only JSON-serializable types:
  /// - Primitives: String, int, double, bool, null
  /// - Collections: List, Map (with JSON-serializable contents)
  /// - DateTime: Convert to ISO 8601 string or milliseconds since epoch
  ///
  /// **Must NOT contain:**
  /// - Function references or closures
  /// - Runtime service instances (AI services, HTTP clients, etc.)
  /// - Platform-specific objects
  /// - Custom class instances (serialize them to maps)
  ///
  /// This payload will be stored in Firestore and used to rehydrate the
  /// task in a different process or at a later time.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// Map<String, dynamic> toPayload() => {
  ///   'taskType': 'data_aggregation',
  ///   'sourceId': sourceId,
  ///   'filters': filters,
  ///   'timestamp': timestamp.toIso8601String(),
  /// };
  /// ```
  Map<String, dynamic> toPayload();

  /// Executes this task with access to Zone-injected services.
  ///
  /// This method is called by the job execution framework with:
  /// - [context]: Execution metadata (job ID, attempt number, timestamp, payload)
  /// - Zone services accessible via `Zone.current[key]`
  ///
  /// **Execution Environment:**
  /// - May run in the main process or in a separate isolate/Cloud Run instance
  /// - Has access to zone services (if configured by executor)
  /// - Should be idempotent where possible
  /// - Should handle service unavailability gracefully
  ///
  /// **Error Handling:**
  /// - Return `ZenResult.ok(data)` on success
  /// - Return `ZenResult.err(error)` on failure
  /// - Thrown exceptions will be caught and wrapped by the executor
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// Future<ZenResult<T>> execute(JobContext context) async {
  ///   final logger = Zone.current['dartzen.logger'] as Logger?;
  ///   logger?.info('Starting execution: ${context.jobId}');
  ///
  ///   try {
  ///     // Perform computation using zone services
  ///     final result = await _performWork();
  ///     return ZenResult.ok(result);
  ///   } catch (e, s) {
  ///     logger?.error('Execution failed', error: e, stackTrace: s);
  ///     return ZenResult.err(
  ///       ZenUnknownError('Task failed: $e', stackTrace: s),
  ///     );
  ///   }
  /// }
  /// ```
  Future<ZenResult<T>> execute(JobContext context);

  /// Checks if the current execution context is within a DartZen executor zone.
  ///
  /// Returns true if `Zone.current['dartzen.executor']` is set to true.
  ///
  /// This is useful for code that needs to behave differently when running
  /// inside an executor vs. in a test or direct invocation context.
  ///
  /// **Example:**
  /// ```dart
  /// if (AggregationTask.isInExecutorZone) {
  ///   // Use zone services
  ///   final logger = Zone.current['dartzen.logger'] as Logger?;
  /// } else {
  ///   // Fallback for non-executor contexts
  ///   print('Running outside executor');
  /// }
  /// ```
  static bool get isInExecutorZone => Zone.current['dartzen.executor'] == true;

  /// Helper method to safely get a service from the current zone.
  ///
  /// Returns null if:
  /// - Not running in an executor zone
  /// - The service key is not registered
  /// - The service is not of type [S]
  ///
  /// **Example:**
  /// ```dart
  /// final logger = AggregationTask.getService<Logger>('dartzen.logger');
  /// logger?.info('Message');
  /// ```
  static S? getService<S>(String key) {
    if (!isInExecutorZone) return null;
    return Zone.current[key] as S?;
  }
}
