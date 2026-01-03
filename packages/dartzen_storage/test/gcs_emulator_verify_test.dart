import 'dart:async';
import 'dart:convert';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _InnerMock extends Mock implements http.Client {}

class _FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBaseRequest());
  });

  test(
    'verifyEmulatorAvailability throws StateError on 500 response',
    () async {
      final inner = _InnerMock();

      when(() => inner.send(any())).thenAnswer(
        (inv) async =>
            // return a StreamedResponse with 500 status
            http.StreamedResponse(
              Stream.fromIterable([utf8.encode('err')]),
              500,
            ),
      );

      final config = GcsStorageConfig(
        projectId: 'p',
        bucket: 'b',
        emulatorHost: '127.0.0.1:1234',
        credentialsMode: GcsCredentialsMode.anonymous,
      );

      final reader = GcsStorageReader(
        config: config,
        httpClientFactory: () => inner,
      );

      // Call the verification method directly to exercise the 500 branch.
      final emulatorClient = EmulatorHttpClient(inner, config.emulatorHost!);
      await expectLater(
        reader.verifyEmulatorAvailabilityForTest(emulatorClient),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'verifyEmulatorAvailability throws StateError when inner throws',
    () async {
      final inner = _InnerMock();

      when(() => inner.send(any())).thenThrow(Exception('network'));

      final config = GcsStorageConfig(
        projectId: 'p',
        bucket: 'b',
        emulatorHost: '127.0.0.1:1235',
        credentialsMode: GcsCredentialsMode.anonymous,
      );

      final reader = GcsStorageReader(
        config: config,
        httpClientFactory: () => inner,
      );

      final emulatorClient = EmulatorHttpClient(inner, config.emulatorHost!);
      await expectLater(
        reader.verifyEmulatorAvailabilityForTest(emulatorClient),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('verifyEmulatorAvailability completes on 200 response', () async {
    final inner = _InnerMock();
    when(() => inner.send(any())).thenAnswer(
      (inv) async =>
          http.StreamedResponse(Stream.fromIterable([utf8.encode('ok')]), 200),
    );

    final config = GcsStorageConfig(
      projectId: 'p',
      bucket: 'b',
      emulatorHost: '127.0.0.1:1236',
      credentialsMode: GcsCredentialsMode.anonymous,
    );

    final reader = GcsStorageReader(
      config: config,
      httpClientFactory: () => inner,
    );

    final emulatorClient = EmulatorHttpClient(inner, config.emulatorHost!);
    await expectLater(
      reader.verifyEmulatorAvailabilityForTest(emulatorClient),
      completes,
    );
  });
}
