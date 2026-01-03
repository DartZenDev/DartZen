import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  group('GcsStorageReader ADC default init override', () {
    test(
      'uses test-overridden ADC initializer when authClientFactory is null',
      () async {
        final mockClient = _MockClient();

        // Override the global ADC initializer to return our mock client.
        gcsClientViaApplicationDefaultCredentials =
            ({List<String>? scopes}) async => mockClient;

        final config = GcsStorageConfig(
          projectId: 'test-project',
          bucket: 'test-bucket',
          credentialsMode: GcsCredentialsMode.applicationDefault,
        );

        final reader = GcsStorageReader(
          config: config,
          // authClientFactory left null to force default path
        );

        final storage = await reader.storageFuture;
        expect(storage, isNotNull);
      },
    );
  });
}
