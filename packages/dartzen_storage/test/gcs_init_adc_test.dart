import 'dart:async';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  group('GcsStorageReader ADC init', () {
    test('uses provided authClientFactory when ADC mode', () async {
      final mockClient = _MockClient();

      // Factory that returns our mock client
      Future<http.Client> factory(List<String> scopes) async => mockClient;

      final config = GcsStorageConfig(
        projectId: 'test-project',
        bucket: 'test-bucket',
        // no emulatorHost -> production-like path
        credentialsMode: GcsCredentialsMode.applicationDefault,
      );

      final reader = GcsStorageReader(
        config: config,
        authClientFactory: factory,
      );

      // Await storage initialization which will invoke our factory
      final storage = await reader.storageFuture;
      expect(storage, isNotNull);
    });
  });
}
