/// Example demonstrating AggregationTask with zone-injected services.
///
/// This example shows how to:
/// 1. Create an AggregationTask that serializes its data to a payload
/// 2. Access zone-injected services at execution time (Firestore, AI client, Logger)
/// 3. Execute heavy aggregation work with proper service isolation
///
/// The UserBehaviorAggregationTask demonstrates a real-world scenario where:
/// - User IDs and time ranges are serialized into the task payload
/// - Firestore client is injected via zones to query user activity data
/// - AI service analyzes patterns and generates insights
/// - Logger tracks progress without being captured in serialized data
// ignore_for_file: avoid_print, public_member_api_docs

library;

import 'dart:async';
import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';

// ============================================================================
// Mock Service Interfaces (in real code, these come from other packages)
// ============================================================================

/// Mock Firestore client interface for demonstration.
abstract class FirestoreClient {
  Future<Map<String, dynamic>> queryUserActivity(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

/// Mock AI service interface for pattern analysis.
abstract class AIService {
  Future<String> analyzePatterns(List<Map<String, dynamic>> activities);
}

/// Mock logger interface.
abstract class Logger {
  void info(String message);
  void error(String message, Object? error);
}

// ============================================================================
// Example: UserBehaviorAggregationTask
// ============================================================================

/// Aggregates user behavior data across multiple users and time periods.
///
/// This task demonstrates the zone injection pattern:
/// - **Serializable Data**: userIds, startDate, endDate, batchSize
/// - **Zone Services**: firestoreClient, aiService, logger
///
/// Usage:
/// ```dart
/// final task = UserBehaviorAggregationTask(
///   userIds: ['user1', 'user2', 'user3'],
///   startDate: DateTime(2024, 1, 1),
///   endDate: DateTime(2024, 1, 31),
///   batchSize: 100,
/// );
///
/// // Services are injected when executing the task
/// final executor = ZenJobsExecutor.development(
///   zoneServices: {
///     'firestoreClient': myFirestoreClient,
///     'aiService': myAIService,
///     'logger': myLogger,
///   },
/// );
///
/// await executor.executeAggregation(task);
/// ```
class UserBehaviorAggregationTask
    extends AggregationTask<Map<String, dynamic>> {
  /// User IDs to aggregate data for.
  final List<String> userIds;

  /// Start date of the analysis period.
  final DateTime startDate;

  /// End date of the analysis period.
  final DateTime endDate;

  /// Number of users to process per batch.
  final int batchSize;

  UserBehaviorAggregationTask({
    required this.userIds,
    required this.startDate,
    required this.endDate,
    this.batchSize = 50,
  });

  @override
  Map<String, dynamic> toPayload() => {
        'userIds': userIds,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'batchSize': batchSize,
      };

  /// Factory to reconstruct task from serialized payload.
  static UserBehaviorAggregationTask fromPayload(
          Map<String, dynamic> payload) =>
      UserBehaviorAggregationTask(
        userIds: List<String>.from(payload['userIds'] as List),
        startDate: DateTime.parse(payload['startDate'] as String),
        endDate: DateTime.parse(payload['endDate'] as String),
        batchSize: payload['batchSize'] as int,
      );

  @override
  Future<ZenResult<Map<String, dynamic>>> execute(JobContext context) async {
    // Verify we're executing within an executor zone
    if (!AggregationTask.isInExecutorZone) {
      return const ZenResult.err(
        ZenValidationError(
          'Task must be executed within an executor zone',
        ),
      );
    }

    // Access zone-injected services (fail fast if not available)
    final firestoreClient =
        AggregationTask.getService<FirestoreClient>('firestoreClient');
    final aiService = AggregationTask.getService<AIService>('aiService');
    final logger = AggregationTask.getService<Logger>('logger');

    if (firestoreClient == null || aiService == null || logger == null) {
      return const ZenResult.err(
        ZenValidationError(
          'Required services not available in zone',
        ),
      );
    }

    try {
      logger.info(
        'Starting user behavior aggregation for ${userIds.length} users '
        'from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      // Aggregate user activities in batches
      final allActivities = <Map<String, dynamic>>[];
      for (var i = 0; i < userIds.length; i += batchSize) {
        final batchEnd = (i + batchSize).clamp(0, userIds.length);
        final batch = userIds.sublist(i, batchEnd);

        logger.info('Processing batch ${i ~/ batchSize + 1}: $batch');

        // Query Firestore for each user's activity
        for (final userId in batch) {
          final activity = await firestoreClient.queryUserActivity(
            userId,
            startDate,
            endDate,
          );
          allActivities.add(activity);
        }

        // Small delay to avoid overwhelming Firestore
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      logger.info('Collected ${allActivities.length} activity records');

      // Use AI service to analyze patterns
      logger.info('Analyzing patterns with AI service...');
      final insights = await aiService.analyzePatterns(allActivities);

      // Generate aggregated result
      final result = {
        'totalUsers': userIds.length,
        'totalActivities': allActivities.length,
        'analysisInsights': insights,
        'dateRange': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'batchesProcessed': (userIds.length / batchSize).ceil(),
        'completedAt': DateTime.now().toIso8601String(),
      };

      logger.info('Aggregation completed successfully');
      return ZenResult.ok(result);
    } catch (e, stackTrace) {
      logger.error('Aggregation failed', e);
      return ZenResult.err(
        ZenUnknownError(
          'Failed to aggregate user behavior: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

// ============================================================================
// Example: ReportGenerationTask
// ============================================================================

/// Generates a comprehensive report by aggregating data from multiple sources.
///
/// Demonstrates a simpler aggregation pattern with fewer dependencies.
class ReportGenerationTask extends AggregationTask<String> {
  /// Report ID for tracking.
  final String reportId;

  /// Type of report to generate.
  final String reportType;

  /// Additional filters for the report.
  final Map<String, dynamic> filters;

  ReportGenerationTask({
    required this.reportId,
    required this.reportType,
    this.filters = const {},
  });

  @override
  Map<String, dynamic> toPayload() => {
        'reportId': reportId,
        'reportType': reportType,
        'filters': filters,
      };

  static ReportGenerationTask fromPayload(Map<String, dynamic> payload) =>
      ReportGenerationTask(
        reportId: payload['reportId'] as String,
        reportType: payload['reportType'] as String,
        filters: payload['filters'] as Map<String, dynamic>? ?? {},
      );

  @override
  Future<ZenResult<String>> execute(JobContext context) async {
    if (!AggregationTask.isInExecutorZone) {
      return const ZenResult.err(
        ZenValidationError(
          'Task must be executed within an executor zone',
        ),
      );
    }

    final firestoreClient =
        AggregationTask.getService<FirestoreClient>('firestoreClient');
    final logger = AggregationTask.getService<Logger>('logger');

    if (firestoreClient == null || logger == null) {
      return const ZenResult.err(
        ZenValidationError(
          'Required services not available in zone',
        ),
      );
    }

    try {
      logger.info('Generating $reportType report: $reportId');

      // Simulate report generation (in real code, query multiple data sources)
      await Future<void>.delayed(const Duration(seconds: 1));

      final report = '''
# Report: $reportType
ID: $reportId
Generated: ${DateTime.now().toIso8601String()}
Filters: ${jsonEncode(filters)}

[Report content would be here]
''';

      logger.info('Report $reportId generated successfully');
      return ZenResult.ok(report);
    } catch (e, stackTrace) {
      logger.error('Report generation failed', e);
      return ZenResult.err(
        ZenUnknownError(
          'Failed to generate report: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

// ============================================================================
// Example Usage Scenarios
// ============================================================================

/// Example: Using UserBehaviorAggregationTask with zone-injected services.
void exampleUsage() {
  // Create mock implementations of services (in real code, use actual services)
  final firestoreClient = _MockFirestoreClient();
  final aiService = _MockAIService();
  final logger = _MockLogger();

  // Create the aggregation task with serializable data
  final _ = UserBehaviorAggregationTask(
    userIds: ['user1', 'user2', 'user3', 'user4', 'user5'],
    startDate: DateTime(2024),
    endDate: DateTime(2024, 1, 31),
    batchSize: 2,
  );

  // Create executor with zone services
  final executor = ZenJobsExecutor.development(
    zoneServices: {
      'dartzen.executor': true, // Required marker for executor zone
      'firestoreClient': firestoreClient,
      'aiService': aiService,
      'logger': logger,
    },
  );

  // Register the handler
  executor.registerHandler(
    'userBehaviorAggregation',
    (context) async {
      // In production, payload would be retrieved from JobStore
      final payload = context.payload!;
      final task = UserBehaviorAggregationTask.fromPayload(payload);
      await task.execute(context);
    },
  );

  // Execute the task (services are accessed via zones, not captured in payload)
  // executor.dispatch(...)
}

// ============================================================================
// Mock Implementations (for demonstration only)
// ============================================================================

class _MockFirestoreClient implements FirestoreClient {
  @override
  Future<Map<String, dynamic>> queryUserActivity(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 50));

    return {
      'userId': userId,
      'activities': [
        {'action': 'login', 'timestamp': startDate.toIso8601String()},
        {'action': 'view_page', 'timestamp': startDate.toIso8601String()},
      ],
    };
  }
}

class _MockAIService implements AIService {
  @override
  Future<String> analyzePatterns(List<Map<String, dynamic>> activities) async {
    // Simulate AI processing
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return 'Users showed increased activity during business hours. '
        'Peak engagement at 10 AM and 3 PM.';
  }
}

class _MockLogger implements Logger {
  @override
  void info(String message) {
    print('[INFO] $message');
  }

  @override
  void error(String message, Object? error) {
    print('[ERROR] $message: $error');
  }
}
