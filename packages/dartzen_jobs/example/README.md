# DartZen Jobs Examples

This directory contains examples demonstrating how to use `dartzen_jobs` for job execution and orchestration with zone-injected services.

## Examples

### 1. Basic Aggregation Task (`aggregation_example.dart`)

**Runnable Example**: ✅ Yes
**Run Command**: `dart run lib/aggregation_example.dart`

A complete, runnable example showing:

- Creating an `AggregationTask` that serializes data to a payload
- Injecting services via zones (`logger`, `dataService`)
- Executing heavy aggregation work with proper service isolation
- Accessing zone services at execution time without capturing them in payloads

**Key Concepts Demonstrated**:

- `UserStatsAggregationTask` extends `AggregationTask<T>`
- `toPayload()` / `fromPayload()` for serialization
- `AggregationTask.isInExecutorZone` for zone detection
- `AggregationTask.getService<T>()` for accessing zone-injected services
- Zone marker `'dartzen.executor': true` required for executor context

**Output**:

```
========================================
AggregationTask with Zone Services Demo
========================================

Task created with 5 users

Executor created with zone services: logger, dataService

---
Executing aggregation task...

[INFO] Starting aggregation: January User Activity Report
[INFO] Processing 5 users...
[INFO] Fetching data for user: user1
[INFO] Fetching data for user: user2
...
[INFO] Aggregation completed: 96 total activities, 19.2 average per user

✓ Task scheduled and executed successfully!
```

### 2. Comprehensive Example (`user_behavior_aggregation_example.dart`)

**Runnable Example**: ❌ No (Reference/Template)
**Purpose**: Comprehensive documentation and patterns

A detailed reference implementation showing:

- **UserBehaviorAggregationTask**: Full-featured aggregation with Firestore, AI service, and batching
- **ReportGenerationTask**: Simpler aggregation pattern
- Mock service interfaces for real-world scenarios
- Comprehensive error handling and logging
- Best practices and usage patterns

**Service Interfaces Demonstrated**:

- `FirestoreClient` - Database queries
- `AIService` - Pattern analysis
- `Logger` - Structured logging

**Key Patterns**:

```dart
// 1. Define serializable task
class MyAggregationTask extends AggregationTask<ResultType> {
  final SerializableData data;  // Only JSON-safe data

  @override
  Map<String, dynamic> toPayload() => {'data': data};

  @override
  Future<ZenResult<ResultType>> execute(JobContext context) async {
    // Access zone services
    final service = AggregationTask.getService<MyService>('myService');
    // ... perform work
  }
}

// 2. Configure executor with services
final executor = ZenJobsExecutor.development(
  zoneServices: {
    'dartzen.executor': true,  // Required marker
    'myService': myServiceInstance,
  },
);

// 3. Register and execute
executor.registerHandler('myTask', (context) async {
  final task = MyAggregationTask.fromPayload(context.payload!);
  await task.execute(context);
});
```

## Core Concepts

### AggregationTask Base Class

The `AggregationTask<T>` abstract class provides:

- **Payload Serialization**: `toPayload()` for converting task to JSON-safe data
- **Execution**: `execute(JobContext)` for performing work with zone-injected services
- **Zone Detection**: `AggregationTask.isInExecutorZone` checks if running in executor
- **Service Access**: `AggregationTask.getService<T>(key)` safely retrieves zone services

### Zone-Based Service Injection

**Why Zones?**

- ✅ Services available at execution time without serialization
- ✅ Clean separation: data in payload, services in zone
- ✅ No risk of capturing non-serializable objects
- ✅ Testability: inject mocks via zones

**Required Zone Values**:

```dart
{
  'dartzen.executor': true,        // Marker indicating executor context
  'logger': loggerInstance,         // Your service instances
  'http.client': httpClient,
  // ... any other services
}
```

### Serialization Pattern

**What Goes in Payload** (serializable):

- User IDs, entity IDs
- Date ranges
- Configuration parameters
- Batch sizes
- Filter criteria

**What Goes in Zone** (non-serializable):

- Database clients
- HTTP clients
- Logger instances
- AI service clients
- Cache managers

## Development Workflow

### 1. Define Your Task

```dart
class MyTask extends AggregationTask<MyResult> {
  final List<String> ids;
  final DateTime startDate;

  MyTask({required this.ids, required this.startDate});

  @override
  Map<String, dynamic> toPayload() => {
    'ids': ids,
    'startDate': startDate.toIso8601String(),
  };

  static MyTask fromPayload(Map<String, dynamic> payload) {
    return MyTask(
      ids: List<String>.from(payload['ids']),
      startDate: DateTime.parse(payload['startDate']),
    );
  }
}
```

### 2. Implement Execute Logic

```dart
@override
Future<ZenResult<MyResult>> execute(JobContext context) async {
  // Verify executor zone
  if (!AggregationTask.isInExecutorZone) {
    return ZenResult.err(ZenValidationError('Must run in executor zone'));
  }

  // Get services
  final logger = AggregationTask.getService<Logger>('logger');
  final db = AggregationTask.getService<Database>('database');

  try {
    // Your work here
    return ZenResult.ok(result);
  } catch (e, s) {
    logger?.error('Task failed', e);
    return ZenResult.err(ZenUnknownError('$e', stackTrace: s));
  }
}
```

### 3. Configure and Execute

```dart
final executor = ZenJobsExecutor.development(
  zoneServices: {
    'dartzen.executor': true,
    'logger': myLogger,
    'database': myDatabase,
  },
);

const descriptor = JobDescriptor(
  id: 'my_task',
  type: JobType.endpoint,
);

executor.register(descriptor);
executor.registerHandler(descriptor.id, (context) async {
  final task = MyTask.fromPayload(context.payload!);
  await task.execute(context);
});

await executor.start();
await executor.schedule(descriptor, payload: task.toPayload());
await executor.shutdown();
```

## Testing

For testing aggregation tasks:

1. Create mock service implementations
2. Inject mocks via `zoneServices`
3. Verify task behavior in isolation

```dart
test('task executes with mocked services', () async {
  final mockLogger = MockLogger();
  final mockDb = MockDatabase();

  final executor = ZenJobsExecutor.development(
    zoneServices: {
      'dartzen.executor': true,
      'logger': mockLogger,
      'database': mockDb,
    },
  );

  // ... register and execute task
});
```

## Best Practices

1. **Keep Payloads JSON-Safe**: Only serialize primitive types, lists, and maps
2. **Always Set dartzen.executor**: Required marker for `isInExecutorZone` to work
3. **Null-Check Services**: Always check if `getService()` returns null
4. **Use ZenResult**: Return `ZenResult<T>` for proper error handling
5. **Log Appropriately**: Use zone-injected logger, not `print()`
6. **Handle Errors Gracefully**: Catch exceptions and wrap in `ZenUnknownError`

## Related Documentation

- **Core Concepts**: See `/docs/execution_model.md` for architecture overview
- **API Reference**: See `AggregationTask` class documentation in `dartzen_jobs`
- **Zone Injection**: See `ZoneConfiguration` in `dartzen_executor` package

## Questions?

For more information, consult:

- `dartzen_jobs` package README
- `AggregationTask` API documentation
- DartZen architecture documentation in `/docs/`
