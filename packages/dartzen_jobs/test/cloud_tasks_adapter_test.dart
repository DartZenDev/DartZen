import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/src/cloud_tasks_adapter.dart';
import 'package:test/test.dart';

void main() {
  late CloudTasksAdapter adapter;

  setUp(() {
    adapter = const CloudTasksAdapter(
      projectId: 'test-project',
      locationId: 'us-central1',
      queueId: 'test-queue',
      serviceUrl: 'https://example.com',
    );
  });

  test('toRequest transforms job details correctly', () {
    const job = JobSubmission('test_job', payload: {'key': 'value'});
    final result = adapter.toRequest(job);

    expect(result.isSuccess, isTrue);
    final request = result.dataOrNull!;

    expect(
      request.url,
      'https://cloudtasks.googleapis.com/v2/projects/test-project/locations/us-central1/queues/test-queue/tasks',
    );
    expect(request.headers, {'Content-Type': 'application/json'});

    // Decode body to verify content
    final bodyJson = jsonDecode(request.body) as Map<String, dynamic>;
    final task = bodyJson['task'] as Map<String, dynamic>;
    final httpRequest = task['httpRequest'] as Map<String, dynamic>;
    final payloadBase64 = httpRequest['body'] as String;
    final decodedPayload = utf8.decode(base64Decode(payloadBase64));

    expect(decodedPayload, contains('test_job'));
    expect(decodedPayload, contains('key'));
    expect(decodedPayload, contains('value'));
    expect(request.scheduleTime, isNull);
  });

  test('toRequest includes scheduleTime when delay is provided', () {
    const job = JobSubmission('test_job');
    const delay = Duration(minutes: 5);
    final result = adapter.toRequest(job, delay: delay);

    expect(result.isSuccess, isTrue);
    final request = result.dataOrNull!;

    expect(request.scheduleTime, isNotNull);

    final bodyJson = jsonDecode(request.body) as Map<String, dynamic>;
    final task = bodyJson['task'] as Map<String, dynamic>;
    expect(task['scheduleTime'], isNotNull);
  });

  test('toRequest accepts deterministic currentTime', () {
    const job = JobSubmission('test_job');
    const delay = Duration(minutes: 5);
    final now = DateTime(2025).toUtc();
    final result = adapter.toRequest(
      job,
      delay: delay,
      currentTime: ZenTimestamp.from(now),
    );

    expect(result.isSuccess, isTrue);
    final request = result.dataOrNull!;

    final expectedTime = now.add(delay).toIso8601String();
    expect(request.scheduleTime, expectedTime);
  });

  test('toRequest returns error for empty jobId', () {
    const job = JobSubmission('');
    final result = adapter.toRequest(job);

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<JobTaskCreationError>());
  });
}
