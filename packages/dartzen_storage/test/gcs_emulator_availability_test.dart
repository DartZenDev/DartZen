import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('GcsStorageReader emulator verification', () {
    final config = GcsStorageConfig(
      projectId: 'test-project',
      bucket: 'test-bucket',
      emulatorHost: 'localhost:8080',
    );

    test('verifyEmulatorAvailability succeeds on 200', () async {
      final reader = GcsStorageReader(
        config: config,
        authClientFactory: (scopes) => Future.value(http.Client()),
      );

      final client = MockClient((request) async => http.Response('ok', 200));

      await reader.verifyEmulatorAvailabilityForTest(client);
    });

    test('verifyEmulatorAvailability throws on 500', () async {
      final reader = GcsStorageReader(
        config: config,
        authClientFactory: (scopes) => Future.value(http.Client()),
      );

      final client = MockClient((request) async => http.Response('err', 500));

      expect(
        () => reader.verifyEmulatorAvailabilityForTest(client),
        throwsA(isA<StateError>()),
      );
    });
  });
}
