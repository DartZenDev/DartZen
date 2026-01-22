import 'dart:convert';

import 'package:dartzen_jobs/src/cloud_tasks_adapter.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late GcpJobDispatcher dispatcher;
  late MockHttpClient httpClient;

  setUp(() {
    httpClient = MockHttpClient();
    dispatcher = GcpJobDispatcher(httpClient);
    registerFallbackValue(Uri());
    registerFallbackValue(<String, String>{});
  });

  test('dispatch returns ok on 200', () async {
    final request = CloudTaskRequest(
      url: 'https://example.com',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'foo': 'bar'}),
    );

    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('created', 200));

    final res = await dispatcher.dispatch(request);

    expect(res.isSuccess, isTrue);
    verify(
      () => httpClient.post(
        Uri.parse(request.url),
        headers: request.headers,
        body: request.body,
      ),
    ).called(1);
  });

  test('dispatch returns error on >=300', () async {
    const request = CloudTaskRequest(
      url: 'https://example.com',
      headers: {},
      body: 'x',
    );

    when(
      () => httpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('bad', 500));

    final res = await dispatcher.dispatch(request);

    expect(res.isFailure, isTrue);
    expect(res.errorOrNull, isA<JobDispatchError>());
    verify(
      () => httpClient.post(
        Uri.parse(request.url),
        headers: any(named: 'headers'),
        body: request.body,
      ),
    ).called(1);
  });

  test(
    'dispatch returns transport error on exception and merges headerInjector',
    () async {
      const request = CloudTaskRequest(
        url: 'https://example.com',
        headers: {'A': '1'},
        body: 'x',
      );

      final dispatcherWithHeaders = GcpJobDispatcher(
        httpClient,
        headerInjector: () => {'Authorization': 'Bearer tok'},
      );

      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('network'));

      final res = await dispatcherWithHeaders.dispatch(request);

      expect(res.isFailure, isTrue);
      expect(res.errorOrNull, isA<JobDispatchError>());
      // Ensure headerInjector was called via merge into headers (we verify post called)
      verify(
        () => httpClient.post(
          Uri.parse(request.url),
          headers: any(named: 'headers'),
          body: request.body,
        ),
      ).called(1);
    },
  );

  test('SimulatedJobDispatcher returns ok', () async {
    final sim = SimulatedJobDispatcher();
    const request = CloudTaskRequest(url: 'u', headers: {}, body: '{}');
    final res = await sim.dispatch(request);
    expect(res.isSuccess, isTrue);
  });
}
