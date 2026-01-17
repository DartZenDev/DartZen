import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_executor/dartzen_executor.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';
import 'package:test/test.dart';

class FakeZenJobs implements ZenJobs {
  FakeZenJobs({this.result, this.shouldThrow = false});

  ZenResult<void>? result;
  bool shouldThrow;
  final List<Map<String, dynamic>> received = [];

  @override
  Future<ZenResult<void>> trigger(
    String jobId, {
    Map<String, dynamic>? payload,
    Duration? delay,
    ZenTimestamp? currentTime,
  }) async {
    received.add({'jobId': jobId, 'payload': payload});
    if (shouldThrow) {
      throw StateError('trigger failure');
    }
    return result ?? const ZenResult.ok(null);
  }

  @override
  void register(JobDefinition definition) {}

  @override
  Future<int> handleRequest(dynamic request) async => 200;
}

void main() {
  group('CloudJobDispatcher', () {
    late FakeZenJobs fakeJobs;
    const dispatcher = CloudJobDispatcher();

    setUp(() {
      fakeJobs = FakeZenJobs(result: const ZenResult.ok(null));
      ZenJobs.instance = fakeJobs;
    });

    test('returns ok when ZenJobs trigger succeeds', () async {
      final result = await dispatcher.dispatch(
        jobId: 'job-1',
        queueId: 'queue-a',
        serviceUrl: 'https://service.test',
        payload: {'taskType': 'ExampleTask'},
      );

      expect(result.isSuccess, isTrue);
      expect(fakeJobs.received, hasLength(1));
      expect(fakeJobs.received.first['jobId'], 'job-1');
      expect(
        fakeJobs.received.first['payload'],
        containsPair('taskType', 'ExampleTask'),
      );
    });

    test('wraps exceptions from ZenJobs.trigger', () async {
      fakeJobs.shouldThrow = true;

      final result = await dispatcher.dispatch(
        jobId: 'job-2',
        queueId: 'queue-b',
        serviceUrl: 'https://service.test',
        payload: {'taskType': 'ExampleTask'},
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
      expect(
        result.errorOrNull!.message,
        contains('Failed to dispatch job to cloud'),
      );
    });
  });
}
