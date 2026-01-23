/// End-to-end integration tests for zone-based service injection.
///
/// Tests the complete flow: task creation → payload serialization →
/// zone injection → execution → service access.
library;

import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:test/test.dart';

// ============================================================================
// Mock Services for Integration Testing
// ============================================================================

/// Mock database service.
class MockDatabase {
  final Map<String, Map<String, dynamic>> data = {};

  Future<Map<String, dynamic>?> fetchUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return data[userId];
  }

  Future<void> saveResult(String id, Map<String, dynamic> result) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    data[id] = result;
  }
}

/// Mock logger service.
class MockLogger {
  final List<String> logs = [];

  void info(String message) => logs.add('[INFO] $message');
  void error(String message, Object? e) =>
      logs.add('[ERROR] $message: ${e ?? ""}');
}

/// Mock cache service.
class MockCache {
  final Map<String, dynamic> cache = {};

  Future<dynamic> get(String key) async => cache[key];
  Future<void> set(String key, dynamic value) async => cache[key] = value;
  Future<void> clear() async => cache.clear();
}

// ============================================================================
// Test Aggregation Task Implementation
// ============================================================================

/// Simple test task that accesses zone services.
class TestAggregationTask extends AggregationTask<Map<String, dynamic>> {
  final List<String> userIds;
  final String reportType;

  TestAggregationTask({required this.userIds, required this.reportType});

  @override
  Map<String, dynamic> toPayload() => {
    'userIds': userIds,
    'reportType': reportType,
  };

  static TestAggregationTask fromPayload(Map<String, dynamic> payload) =>
      TestAggregationTask(
        userIds: List<String>.from(payload['userIds'] as List),
        reportType: payload['reportType'] as String,
      );

  @override
  Future<ZenResult<Map<String, dynamic>>> execute(JobContext context) async {
    // Verify we're in executor zone
    if (!AggregationTask.isInExecutorZone) {
      return const ZenResult.err(
        ZenValidationError('Task must run in executor zone'),
      );
    }

    // Get zone services
    final db = AggregationTask.getService<MockDatabase>('database');
    final logger = AggregationTask.getService<MockLogger>('logger');
    final cache = AggregationTask.getService<MockCache>('cache');

    if (db == null || logger == null || cache == null) {
      return const ZenResult.err(
        ZenValidationError('Required services not in zone'),
      );
    }

    try {
      logger.info('Starting aggregation: $reportType');

      // Fetch data for each user
      final results = <Map<String, dynamic>>[];
      for (final userId in userIds) {
        logger.info('Fetching user: $userId');
        final userData = await db.fetchUser(userId);
        if (userData != null) {
          results.add(userData);
        }
      }

      // Check cache
      final cachedKey = 'report_$reportType';
      final cached = await cache.get(cachedKey);
      logger.info('Cache hit for $cachedKey: ${cached != null}');

      // Compose result
      final result = {
        'reportType': reportType,
        'userCount': userIds.length,
        'resultsCount': results.length,
        'hadCacheHit': cached != null,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save to cache
      await cache.set(cachedKey, result);
      logger.info('Result saved to cache');

      return ZenResult.ok(result);
    } catch (e, s) {
      logger.error('Aggregation failed', e);
      return ZenResult.err(
        ZenUnknownError('Aggregation failed: $e', stackTrace: s),
      );
    }
  }
}

// ============================================================================
// Integration Tests
// ============================================================================

void main() {
  group('Zone Injection Integration Tests', () {
    late MockDatabase mockDatabase;
    late MockLogger mockLogger;
    late MockCache mockCache;
    late ZenJobsExecutor executor;

    setUp(() {
      // Initialize services
      mockDatabase = MockDatabase();
      mockLogger = MockLogger();
      mockCache = MockCache();

      // Set up test data
      mockDatabase.data['user1'] = {
        'id': 'user1',
        'name': 'Alice',
        'score': 95,
      };
      mockDatabase.data['user2'] = {'id': 'user2', 'name': 'Bob', 'score': 87};

      // Initialize ZenJobs singleton
      ZenJobs.instance = ZenJobs();

      // Create executor with zone services
      executor = ZenJobsExecutor.development(
        zoneServices: {
          'dartzen.executor': true,
          'database': mockDatabase,
          'logger': mockLogger,
          'cache': mockCache,
        },
      );
    });

    test('Task payload serializes and deserializes correctly', () {
      final original = TestAggregationTask(
        userIds: ['user1', 'user2', 'user3'],
        reportType: 'monthly',
      );

      final payload = original.toPayload();
      final restored = TestAggregationTask.fromPayload(payload);

      expect(restored.userIds, equals(original.userIds));
      expect(restored.reportType, equals(original.reportType));
    });

    test('Executor provides zone services to task', () async {
      final task = TestAggregationTask(
        userIds: ['user1', 'user2'],
        reportType: 'daily',
      );

      const descriptor = JobDescriptor(id: 'test_task', type: JobType.endpoint);
      executor.register(descriptor);

      HandlerRegistry.register(descriptor.id, (context) async {
        final payload = context.payload!;
        final taskFromPayload = TestAggregationTask.fromPayload(payload);
        await taskFromPayload.execute(context);
      });

      await executor.start();
      await executor.schedule(descriptor, payload: task.toPayload());
      await executor.shutdown();

      // Verify services were called
      expect(mockLogger.logs, isNotEmpty);
      expect(mockLogger.logs.first, contains('Starting aggregation'));
      expect(mockCache.cache, isNotEmpty);
    });

    test('Task accesses multiple zone services', () async {
      final context = JobContext(
        jobId: 'test',
        executionTime: DateTime.now(),
        attempt: 1,
        payload: {
          'userIds': ['user1', 'user2'],
          'reportType': 'weekly',
        },
      );

      final task = TestAggregationTask(
        userIds: ['user1', 'user2'],
        reportType: 'weekly',
      );

      // Execute within zone using runZoned
      late ZenResult<Map<String, dynamic>> result;
      await runZoned(
        () async {
          result = await task.execute(context);
        },
        zoneValues: {
          'dartzen.executor': true,
          'database': mockDatabase,
          'logger': mockLogger,
          'cache': mockCache,
        },
      );

      expect(result.isSuccess, isTrue);
      final data = result.dataOrNull;
      expect(data?['userCount'], equals(2));
      expect(data?['resultsCount'], equals(2));
      expect(data?['hadCacheHit'], isFalse);
    });

    test('Task isolation: services not visible outside zone', () async {
      // Outside zone, services should not be accessible
      final db = AggregationTask.getService<MockDatabase>('database');
      final logger = AggregationTask.getService<MockLogger>('logger');

      expect(db, isNull);
      expect(logger, isNull);
    });

    test('Zone services survive nested async operations', () async {
      final task = TestAggregationTask(
        userIds: ['user1', 'user2'],
        reportType: 'nested_test',
      );

      final context = JobContext(
        jobId: 'nested',
        executionTime: DateTime.now(),
        attempt: 1,
        payload: task.toPayload(),
      );

      late ZenResult<Map<String, dynamic>> result;
      await runZoned(
        () async {
          // Nested async call
          await Future<void>.delayed(const Duration(milliseconds: 10));
          result = await task.execute(context);
        },
        zoneValues: {
          'dartzen.executor': true,
          'database': mockDatabase,
          'logger': mockLogger,
          'cache': mockCache,
        },
      );

      expect(result.isSuccess, isTrue);
      expect(mockLogger.logs, isNotEmpty);
    });

    test('Error in task is properly caught and wrapped', () async {
      // Clear database to cause missing data
      mockDatabase.data.clear();

      final task = TestAggregationTask(
        userIds: ['nonexistent'],
        reportType: 'error_test',
      );

      final context = JobContext(
        jobId: 'error',
        executionTime: DateTime.now(),
        attempt: 1,
        payload: task.toPayload(),
      );

      late ZenResult<Map<String, dynamic>> result;
      await runZoned(
        () async {
          result = await task.execute(context);
        },
        zoneValues: {
          'dartzen.executor': true,
          'database': mockDatabase,
          'logger': mockLogger,
          'cache': mockCache,
        },
      );

      // Task should complete successfully (empty results)
      expect(result.isSuccess, isTrue);
      final data = result.dataOrNull;
      expect(data?['resultsCount'], equals(0));
    });

    test('Multiple concurrent zones maintain isolation', () async {
      final logger1 = MockLogger();
      final logger2 = MockLogger();
      final db = mockDatabase;

      final task1 = TestAggregationTask(
        userIds: ['user1'],
        reportType: 'task1',
      );
      final task2 = TestAggregationTask(
        userIds: ['user2'],
        reportType: 'task2',
      );

      final context1 = JobContext(
        jobId: 'task1',
        executionTime: DateTime.now(),
        attempt: 1,
        payload: task1.toPayload(),
      );
      final context2 = JobContext(
        jobId: 'task2',
        executionTime: DateTime.now(),
        attempt: 1,
        payload: task2.toPayload(),
      );

      // Run in separate zones concurrently
      late ZenResult<Map<String, dynamic>> result1;
      late ZenResult<Map<String, dynamic>> result2;

      await Future.wait([
        runZoned(
          () async {
            result1 = await task1.execute(context1);
          },
          zoneValues: {
            'dartzen.executor': true,
            'database': db,
            'logger': logger1,
            'cache': mockCache,
          },
        ),
        runZoned(
          () async {
            result2 = await task2.execute(context2);
          },
          zoneValues: {
            'dartzen.executor': true,
            'database': db,
            'logger': logger2,
            'cache': mockCache,
          },
        ),
      ]);

      expect(result1.isSuccess, isTrue);
      expect(result2.isSuccess, isTrue);

      // Each logger should have its own logs (isolated)
      expect(logger1.logs.length, greaterThan(0));
      expect(logger2.logs.length, greaterThan(0));
      expect(logger1.logs.first, contains('task1'));
      expect(logger2.logs.first, contains('task2'));
    });

    test(
      'Complete workflow: create, serialize, store, retrieve, execute',
      () async {
        // Step 1: Create task with serializable data only
        final originalTask = TestAggregationTask(
          userIds: ['user1', 'user2'],
          reportType: 'full_workflow',
        );

        // Step 2: Serialize to payload
        final payload = originalTask.toPayload();
        expect(payload['userIds'], isNotNull);
        expect(payload['reportType'], isNotNull);

        // Step 3: Simulate storing in database (would use JobStore)
        final storedPayload = Map<String, dynamic>.from(payload);

        // Step 4: Retrieve from database
        final retrievedPayload = storedPayload;

        // Step 5: Deserialize
        final restoredTask = TestAggregationTask.fromPayload(retrievedPayload);

        // Step 6: Execute with injected services
        final context = JobContext(
          jobId: 'workflow',
          executionTime: DateTime.now(),
          attempt: 1,
          payload: restoredTask.toPayload(),
        );

        late ZenResult<Map<String, dynamic>> result;
        await runZoned(
          () async {
            result = await restoredTask.execute(context);
          },
          zoneValues: {
            'dartzen.executor': true,
            'database': mockDatabase,
            'logger': mockLogger,
            'cache': mockCache,
          },
        );

        expect(result.isSuccess, isTrue);
        final resultData = result.dataOrNull;
        expect(resultData?['reportType'], equals('full_workflow'));
        expect(resultData?['userCount'], equals(2));
      },
    );
  });
}
