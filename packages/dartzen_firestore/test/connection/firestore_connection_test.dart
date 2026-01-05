import 'package:dartzen_firestore/src/connection/firestore_config.dart';
import 'package:dartzen_firestore/src/connection/firestore_connection.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreConnection', () {
    late MockClient mockClient;

    setUp(() {
      FirestoreConnection.reset();
      mockClient = MockClient(
        (request) async => http.Response('{"documents": []}', 200),
      );
    });

    tearDown(FirestoreConnection.reset);

    test('isInitialized returns false initially', () {
      expect(FirestoreConnection.isInitialized, isFalse);
    });

    test('client getter throws StateError when not initialized', () {
      expect(
        () => FirestoreConnection.client,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not been initialized'),
          ),
        ),
      );
    });

    test('initialize throws StateError when called twice', () async {
      const config = FirestoreConfig.emulator(projectId: 'test');

      await FirestoreConnection.initialize(config, httpClient: mockClient);
      expect(FirestoreConnection.isInitialized, isTrue);

      expect(
        () => FirestoreConnection.initialize(config, httpClient: mockClient),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already initialized'),
          ),
        ),
      );
    });

    test('initialize succeeds for emulator mode with valid response', () async {
      const config = FirestoreConfig.emulator(projectId: 'test');

      await FirestoreConnection.initialize(config, httpClient: mockClient);

      expect(FirestoreConnection.isInitialized, isTrue);
      expect(FirestoreConnection.client, isNotNull);
    });

    test('initialize succeeds for production mode', () async {
      const config = FirestoreConfig.production(projectId: 'test');

      await FirestoreConnection.initialize(config, httpClient: mockClient);

      expect(FirestoreConnection.isInitialized, isTrue);
      expect(FirestoreConnection.client, isNotNull);
    });

    test(
      'initialize throws StateError when emulator returns 5xx error',
      () async {
        final failingClient = MockClient(
          (request) async => http.Response('Internal Server Error', 500),
        );

        const config = FirestoreConfig.emulator(projectId: 'test');

        expect(
          () =>
              FirestoreConnection.initialize(config, httpClient: failingClient),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not accessible'),
            ),
          ),
        );
      },
    );

    test('reset clears initialization state', () async {
      const config = FirestoreConfig.emulator(projectId: 'test');

      await FirestoreConnection.initialize(config, httpClient: mockClient);
      expect(FirestoreConnection.isInitialized, isTrue);

      FirestoreConnection.reset();
      expect(FirestoreConnection.isInitialized, isFalse);

      expect(() => FirestoreConnection.client, throwsA(isA<StateError>()));
    });
  });
}

