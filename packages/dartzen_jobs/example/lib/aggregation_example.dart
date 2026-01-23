/// Complete runnable example showing AggregationTask with zone-injected services.
///
/// Run this example with:
/// ```bash
/// cd packages/dartzen_jobs/example
/// dart run lib/aggregation_example.dart
/// ```
library;

import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';

// ignore_for_file: avoid_print

// ============================================================================
// Mock Service Implementations
// ============================================================================

/// Simple logger that prints to console.
class SimpleLogger {
  void info(String message) => print('[INFO] $message');
  void error(String message, Object? error) =>
      print('[ERROR] $message: $error');
}

/// Mock data service that simulates fetching user data.
class DataService {
  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return {
      'userId': userId,
      'name': 'User $userId',
      'activityCount': 10 + userId.hashCode % 20,
      'lastSeen': DateTime.now()
          .subtract(Duration(hours: userId.hashCode % 72))
          .toIso8601String(),
    };
  }
}

// ============================================================================
// Example AggregationTask Implementation
// ============================================================================

/// Aggregates statistics across multiple user IDs.
class UserStatsAggregationTask extends AggregationTask<Map<String, dynamic>> {
  final List<String> userIds;
  final String reportName;

  UserStatsAggregationTask({
    required this.userIds,
    required this.reportName,
  });

  @override
  Map<String, dynamic> toPayload() => {
        'userIds': userIds,
        'reportName': reportName,
      };

  static UserStatsAggregationTask fromPayload(Map<String, dynamic> payload) =>
      UserStatsAggregationTask(
        userIds: List<String>.from(payload['userIds'] as List),
        reportName: payload['reportName'] as String,
      );

  @override
  Future<ZenResult<Map<String, dynamic>>> execute(JobContext context) async {
    // Verify we're in an executor zone
    if (!AggregationTask.isInExecutorZone) {
      return const ZenResult.err(
        ZenValidationError(
          'Task must be executed within an executor zone',
        ),
      );
    }

    // Get zone-injected services
    final logger = AggregationTask.getService<SimpleLogger>('logger');
    final dataService = AggregationTask.getService<DataService>('dataService');

    if (logger == null || dataService == null) {
      return const ZenResult.err(
        ZenValidationError(
          'Required services not available in zone',
        ),
      );
    }

    try {
      logger.info('Starting aggregation: $reportName');
      logger.info('Processing ${userIds.length} users...');

      // Fetch data for all users
      final allUserData = <Map<String, dynamic>>[];
      for (final userId in userIds) {
        logger.info('Fetching data for user: $userId');
        final userData = await dataService.fetchUserData(userId);
        allUserData.add(userData);
      }

      // Compute aggregate statistics
      final totalActivity = allUserData.fold<int>(
        0,
        (sum, user) => sum + (user['activityCount'] as int),
      );
      final avgActivity = totalActivity / allUserData.length;

      final result = {
        'reportName': reportName,
        'totalUsers': userIds.length,
        'totalActivity': totalActivity,
        'averageActivity': avgActivity,
        'completedAt': DateTime.now().toIso8601String(),
        'users': allUserData,
      };

      logger.info('Aggregation completed: $totalActivity total activities, '
          '${avgActivity.toStringAsFixed(1)} average per user');

      return ZenResult.ok(result);
    } catch (e, stackTrace) {
      logger.error('Aggregation failed', e);
      return ZenResult.err(
        ZenUnknownError(
          'Failed to aggregate user stats: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

// ============================================================================
// Main Example
// ============================================================================

Future<void> main() async {
  print('========================================');
  print('AggregationTask with Zone Services Demo');
  print('========================================\n');

  // Initialize the ZenJobs singleton
  ZenJobs.instance = ZenJobs();

  // Create service instances (these will be injected via zones)
  final logger = SimpleLogger();
  final dataService = DataService();

  // Create the aggregation task
  final task = UserStatsAggregationTask(
    userIds: ['user1', 'user2', 'user3', 'user4', 'user5'],
    reportName: 'January User Activity Report',
  );

  print('Task created with ${task.userIds.length} users\n');

  // Create executor with zone-injected services
  final executor = ZenJobsExecutor.development(
    zoneServices: {
      'dartzen.executor': true, // Required marker for executor zone
      'logger': logger,
      'dataService': dataService,
    },
  );

  print('Executor created with zone services: logger, dataService\n');

  // Register a job descriptor for aggregation tasks
  const descriptor = JobDescriptor(
    id: 'user_stats_aggregation',
    type: JobType.endpoint,
  );

  executor.register(descriptor);

  // Register handler that executes the aggregation task
  executor.registerHandler(descriptor.id, (context) async {
    // Reconstruct task from payload
    final payload = context.payload;
    final task = UserStatsAggregationTask.fromPayload(payload!);

    // Execute task (services are accessed from zone)
    final result = await task.execute(context);

    if (!result.isSuccess) {
      logger.error('Task failed', result.errorOrNull);
    }
  });

  await executor.start();

  print('---\nExecuting aggregation task...\n');

  // Schedule the job with the task's payload
  await executor.schedule(
    descriptor,
    payload: task.toPayload(),
  );

  // Wait a bit for async execution
  await Future.delayed(const Duration(seconds: 1));

  print('\n✓ Task scheduled and executed successfully!');
  print('\n(In production, retrieve results from JobStore)');

  await executor.shutdown();

  print('\n========================================');
  print('Demo completed');
  print('========================================');
}
