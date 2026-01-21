import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_jobs/src/job_store.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late JobStore store;
  late MockHttpClient httpClient;

  setUp(() async {
    httpClient = MockHttpClient();
    FirestoreConnection.reset();
    await FirestoreConnection.initialize(
      FirestoreConfig(projectId: 'test'),
      httpClient: httpClient,
    );
    store = JobStore();
    registerFallbackValue(Uri());
  });

  test('updateJobState sends patch with provided fields', () async {
    Uri? recordedUri;
    when(
      () => httpClient.patch(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      recordedUri = invocation.positionalArguments.isNotEmpty
          ? invocation.positionalArguments[0] as Uri
          : null;
      return http.Response('{}', 200);
    });

    final now = DateTime.utc(2025);
    final res = await store.updateJobState(
      'job1',
      lastRun: now,
      currentRetries: 2,
    );

    expect(res.isSuccess, isTrue);
    // Verify that a patch was sent to the correct document path
    expect(recordedUri, isNotNull);
    expect(recordedUri.toString(), contains('/documents/jobs/job1'));
  });

  test('updateJobState returns ok when no updates provided', () async {
    final res = await store.updateJobState('job1');
    expect(res.isSuccess, isTrue);
  });
}
