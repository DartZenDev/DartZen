import 'dart:convert';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _InnerMock3 extends Mock implements http.Client {}

class _FakeBaseRequest3 extends Fake implements http.BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBaseRequest3());
  });

  test('storageFuture runs _initStorage and verifies emulator', () async {
    final inner = _InnerMock3();
    when(() => inner.send(any())).thenAnswer(
      (_) async =>
          http.StreamedResponse(Stream.fromIterable([utf8.encode('ok')]), 200),
    );

    final config = GcsStorageConfig(
      projectId: 'p',
      bucket: 'b',
      emulatorHost: '127.0.0.1:4322',
      credentialsMode: GcsCredentialsMode.anonymous,
    );

    final reader = GcsStorageReader(
      config: config,
      httpClientFactory: () => inner,
    );

    final storage = await reader.storageFuture;
    expect(storage, isNotNull);
  });
}
