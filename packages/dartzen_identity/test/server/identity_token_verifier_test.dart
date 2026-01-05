import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/server.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityTokenVerifier', () {
    test('verifyToken returns external identity data on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.body, jsonEncode({'idToken': 'valid_token'}));

        return http.Response(
          jsonEncode({
            'users': [
              {
                'localId': 'user_123',
                'email': 'test@example.com',
                'emailVerified': true,
                'displayName': 'Test User',
                'photoUrl': 'https://example.com/photo.jpg',
              },
            ],
          }),
          200,
        );
      });

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('valid_token');

      expect(result.isSuccess, isTrue);
      final data = result.dataOrNull!;
      expect(data.userId, 'user_123');
      expect(data.email, 'test@example.com');
      expect(data.emailVerified, isTrue);
      expect(data.displayName, 'Test User');
      expect(data.photoUrl, 'https://example.com/photo.jpg');

      verifier.close();
    });

    test('verifyToken handles missing optional fields', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'users': [
              {'localId': 'user_456'},
            ],
          }),
          200,
        ),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('token');

      expect(result.isSuccess, isTrue);
      final data = result.dataOrNull!;
      expect(data.userId, 'user_456');
      expect(data.email, isNull);
      expect(data.emailVerified, isFalse);
      expect(data.displayName, isNull);
      expect(data.photoUrl, isNull);

      verifier.close();
    });

    test('verifyToken returns error for empty token', () async {
      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(projectId: 'test-project'),
      );

      final result = await verifier.verifyToken('');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenValidationError>());

      verifier.close();
    });

    test('verifyToken returns unauthorized error for 400 response', () async {
      final mockClient = MockClient(
        (request) async => http.Response('Invalid token', 400),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('invalid_token');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());

      verifier.close();
    });

    test('verifyToken returns error for non-200/400 response', () async {
      final mockClient = MockClient(
        (request) async => http.Response('Server error', 500),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('token');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());

      verifier.close();
    });

    test('verifyToken returns error for empty users array', () async {
      final mockClient = MockClient(
        (request) async =>
            http.Response(jsonEncode({'users': <dynamic>[]}), 200),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('token');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());

      verifier.close();
    });

    test('verifyToken returns error for missing localId', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'users': [
              {'email': 'test@example.com'},
            ],
          }),
          200,
        ),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('token');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());

      verifier.close();
    });

    test('verifyToken handles network errors gracefully', () async {
      final mockClient = MockClient(
        (request) async => throw Exception('Network error'),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('token');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());

      verifier.close();
    });

    test('verifyToken handles malformed JSON response', () async {
      final mockClient = MockClient(
        (request) async => http.Response('not json', 200),
      );

      final verifier = IdentityTokenVerifier(
        config: IdentityTokenVerifierConfig(
          projectId: 'test-project',
          httpClient: mockClient,
        ),
      );

      final result = await verifier.verifyToken('token');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());

      verifier.close();
    });
  });

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

  group('ExternalIdentityData', () {
    test('toString includes userId, email and emailVerified', () {
      const data = ExternalIdentityData(
        userId: 'user_123',
        email: 'test@example.com',
        emailVerified: true,
        displayName: 'Test User',
      );

      expect(data.toString(), contains('user_123'));
      expect(data.toString(), contains('test@example.com'));
      expect(data.toString(), contains('true'));
    });

    test('can be created with only userId', () {
      const data = ExternalIdentityData(userId: 'user_123');

      expect(data.userId, 'user_123');
      expect(data.email, isNull);
      expect(data.emailVerified, isFalse);
      expect(data.displayName, isNull);
      expect(data.photoUrl, isNull);
    });
  });
}
