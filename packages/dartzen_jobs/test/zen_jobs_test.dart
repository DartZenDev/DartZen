import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:dartzen_jobs/src/cloud_tasks_adapter.dart';
import 'package:dartzen_jobs/src/job_runner.dart';
import 'package:dartzen_jobs/src/job_store.dart';
import 'package:dartzen_jobs/src/master_job.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockJobStore extends Mock implements JobStore {}

class MockJobRunner extends Mock implements JobRunner {}

class MockCloudTasksAdapter extends Mock implements CloudTasksAdapter {}

class MockJobDispatcher extends Mock implements JobDispatcher {}

class MockMasterJob extends Mock implements MasterJob {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

void main() {
  late ZenJobs zenJobs;
  late MockJobStore store;
  late MockJobRunner runner;
  late MockCloudTasksAdapter cloudTasks;
  late MockJobDispatcher dispatcher;
  late MockMasterJob masterJob;
  late MockTelemetryClient telemetry;

  setUp(() {
    store = MockJobStore();
    runner = MockJobRunner();
    cloudTasks = MockCloudTasksAdapter();
    dispatcher = MockJobDispatcher();
    masterJob = MockMasterJob();
    telemetry = MockTelemetryClient();

    zenJobs = ZenJobs.custom(
      store: store,
      runner: runner,
      cloudTasks: cloudTasks,
      dispatcher: dispatcher,
      masterJob: masterJob,
      telemetry: telemetry,
    );

    registerFallbackValue(
      JobContext(jobId: 'id', executionTime: DateTime.now(), attempt: 1),
    );
  });

  group('handleRequest', () {
    test('returns 200 on successful job execution', () async {
      when(
        () => runner.execute('test_job', payload: any(named: 'payload')),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      final status = await zenJobs.handleRequest({
        'jobId': 'test_job',
        'payload': <String, dynamic>{},
      });
      expect(status, 200);
    });

    test('returns 400 for malformed JSON string', () async {
      final status = await zenJobs.handleRequest('{invalid json}');
      expect(status, 400);
    });

    test('returns 400 if jobId is missing', () async {
      final status = await zenJobs.handleRequest({'noJobId': 'here'});
      expect(status, 400);
    });

    test('returns 404 if job not found (ZenNotFoundError)', () async {
      when(
        () => runner.execute(any(), payload: any(named: 'payload')),
      ).thenAnswer(
        (_) async => const ZenResult.err(ZenNotFoundError('Not found')),
      );

      final status = await zenJobs.handleRequest({'jobId': 'unknown'});
      expect(status, 404);
    });

    test('returns 400 if validation fails (ZenValidationError)', () async {
      when(
        () => runner.execute(any(), payload: any(named: 'payload')),
      ).thenAnswer(
        (_) async => const ZenResult.err(ZenValidationError('Invalid')),
      );

      final status = await zenJobs.handleRequest({'jobId': 'invalid'});
      expect(status, 400);
    });

    test('returns 500 for other ZenErrors', () async {
      when(
        () => runner.execute(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async => const ZenResult.err(ZenUnknownError('Boom')));

      final status = await zenJobs.handleRequest({'jobId': 'fail'});
      expect(status, 500);
    });

    test('routes to MasterJob if jobId matches masterJobId', () async {
      when(
        () => masterJob.run(any()),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      final status = await zenJobs.handleRequest({
        'jobId': ZenJobs.masterJobId,
      });
      expect(status, 200);
      verify(() => masterJob.run(any())).called(1);
    });

    test('accepts JSON encoded string as request body', () async {
      when(
        () => runner.execute('test_job', payload: any(named: 'payload')),
      ).thenAnswer((_) async => const ZenResult.ok(null));

      final status = await zenJobs.handleRequest(
        jsonEncode({'jobId': 'test_job'}),
      );
      expect(status, 200);
    });
  });
}
