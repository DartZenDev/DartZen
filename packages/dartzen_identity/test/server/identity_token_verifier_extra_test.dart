import 'package:dartzen_identity/server.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('IdentityTokenVerifierConfig', () {
    test('throws if projectId is empty', () {
      expect(
        () => IdentityTokenVerifierConfig(projectId: ''),
        throwsA(isA<StateError>()),
      );
    });
    test('accepts valid projectId', () {
      final config = IdentityTokenVerifierConfig(projectId: 'foo');
      expect(config.projectId, 'foo');
    });
    test('accepts httpClient', () {
      final client = http.Client();
      final config = IdentityTokenVerifierConfig(
        projectId: 'foo',
        httpClient: client,
      );
      expect(config.httpClient, client);
    });
  });
}
