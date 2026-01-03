import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('FirebaseStorageReader.close', () {
    test('closes the http client', () {
      final mockClient = MockHttpClient();
      final reader = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: 'bucket',
          emulatorHost: 'localhost:9199',
        ),
        httpClient: mockClient,
      );
      reader.close();
      verify(mockClient.close).called(1);
    });
  });
}
