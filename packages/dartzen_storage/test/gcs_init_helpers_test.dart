import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBaseRequest());
  });

  test(
    'can override and call gcsClientViaApplicationDefaultCredentials safely',
    () async {
      final mock = _MockClient();

      // Backup and restore original value
      final old = gcsClientViaApplicationDefaultCredentials;
      gcsClientViaApplicationDefaultCredentials =
          ({List<String>? scopes}) async => mock;

      try {
        final client = await gcsClientViaApplicationDefaultCredentials(
          scopes: ['x'],
        );
        expect(client, equals(mock));
      } finally {
        gcsClientViaApplicationDefaultCredentials = old;
      }
    },
  );

  test(
    'initAndVerifyForTest executes emulator verification await branch',
    () async {
      final inner = _MockClient();
      when(() => inner.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.fromIterable([
            <int>[1, 2, 3],
          ]),
          200,
        ),
      );

      final config = GcsStorageConfig(
        projectId: 'p',
        bucket: 'b',
        emulatorHost: '127.0.0.1:4000',
        credentialsMode: GcsCredentialsMode.anonymous,
      );

      final reader = GcsStorageReader(
        config: config,
        authClientFactory: (scopes) => Future.value(http.Client()),
      );

      final storage = await reader.initAndVerifyForTest(inner);
      expect(storage, isNotNull);
    },
  );
}
