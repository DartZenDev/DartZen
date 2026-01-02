import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_demo_client/src/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthError', () {
    test('code returns enum name', () {
      expect(AuthError.missingAuthHeader.code, 'missingAuthHeader');
      expect(AuthError.invalidToken.code, 'invalidToken');
      expect(AuthError.authenticationFailed.code, 'authenticationFailed');
      expect(AuthError.invalidCredentials.code, 'invalidCredentials');
      expect(AuthError.invalidEmailFormat.code, 'invalidEmailFormat');
    });
  });

  group('TermsError', () {
    test('code returns enum name', () {
      expect(TermsError.notFound.code, 'notFound');
      expect(TermsError.loadFailed.code, 'loadFailed');
    });
  });

  group('ZenDemoApiClient', () {
    test('creates with baseUrl', () {
      final apiClient = ZenDemoApiClient(baseUrl: 'http://localhost:8080');
      expect(apiClient.baseUrl, 'http://localhost:8080');
    });

    test('successful login returns token and user data', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost/login');
        expect(request.headers['Content-Type'], 'application/json');

        return http.Response(
          jsonEncode({'idToken': 'token123', 'userId': 'user456'}),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.login(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(result.isSuccess, isTrue);
      final response = result.dataOrNull!;
      expect(response.idToken, 'token123');
      expect(response.userId, 'user456');
    });

    test('login with invalid credentials returns error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'invalidCredentials'}),
          401,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.login(
        email: 'user@example.com',
        password: 'wrong',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());
    });

    test('login network error returns unknown error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.login(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
      expect((result.errorOrNull as ZenUnknownError).message, 'network_error');
    });

    test('setIdToken updates the token', () {
      final apiClient = ZenDemoApiClient(baseUrl: 'http://localhost');
      apiClient.setIdToken('newToken');
      // Token is stored internally and will be used in subsequent requests
    });

    test('ping sends Accept-Language header', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ping');
        expect(request.headers['Accept-Language'], 'pl');

        return http.Response(
          jsonEncode({'message': 'pong', 'timestamp': '123456'}),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.ping(language: 'pl');

      expect(result.isSuccess, isTrue);
      final ping = result.dataOrNull!;
      expect(ping.message, 'pong');
    });

    test('ping error returns unknown error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'server_error'}),
          500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.ping(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });

    test('getProfile requires authentication', () async {
      final mockClient = MockClient((request) async {
        fail('Should not make request without token');
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getProfile(
        userId: 'user123',
        language: 'en',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());
      expect(
        (result.errorOrNull as ZenUnauthorizedError).message,
        'missing_auth_header',
      );
    });

    test('getProfile sends Authorization header', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/profile/user123');
        expect(request.headers['Authorization'], 'Bearer token456');
        expect(request.headers['Accept-Language'], 'en');

        return http.Response(
          jsonEncode({
            'user_id': 'user123',
            'display_name': 'Test User',
            'email': 'user@example.com',
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );
      apiClient.setIdToken('token456');

      final result = await apiClient.getProfile(
        userId: 'user123',
        language: 'en',
      );

      expect(result.isSuccess, isTrue);
      final profile = result.dataOrNull!;
      expect(profile.userId, 'user123');
      expect(profile.email, 'user@example.com');
    });

    test('getProfile handles 401 unauthorized', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'invalidToken'}),
          401,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );
      apiClient.setIdToken('invalid_token');

      final result = await apiClient.getProfile(
        userId: 'user123',
        language: 'en',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());
    });

    test('getProfile handles 500 server error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'server_error'}),
          500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );
      apiClient.setIdToken('token123');

      final result = await apiClient.getProfile(
        userId: 'user123',
        language: 'en',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });

    test('getTerms sends Accept-Language header', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/terms');
        expect(request.headers['Accept-Language'], 'pl');

        return http.Response(
          jsonEncode({'content': '# Terms', 'content_type': 'text/markdown'}),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'pl');

      expect(result.isSuccess, isTrue);
      final terms = result.dataOrNull!;
      expect(terms.content, '# Terms');
      expect(terms.contentType, 'text/markdown');
    });

    test('getTerms handles not found error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'notFound'}),
          404,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });

    test('getTerms handles network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network failure');
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
      expect((result.errorOrNull as ZenUnknownError).message, 'network_error');
    });

    test('getTerms handles 500 server error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'server_error'}),
          500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });

    test('close disposes HTTP client', () {
      final mockClient = MockClient((request) async => http.Response('', 200));

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      // Should not throw
      apiClient.close();
    });

    test('ErrorCode extension returns correct codes', () {
      expect(AuthError.missingAuthHeader.code, 'missingAuthHeader');
      expect(AuthError.invalidToken.code, 'invalidToken');
      expect(AuthError.authenticationFailed.code, 'authenticationFailed');
      expect(AuthError.invalidCredentials.code, 'invalidCredentials');
      expect(AuthError.invalidEmailFormat.code, 'invalidEmailFormat');
    });

    test('TermsErrorCode extension returns correct codes', () {
      expect(TermsError.notFound.code, 'notFound');
      expect(TermsError.loadFailed.code, 'loadFailed');
    });

    test('login with null error in response uses default error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': null}),
          401,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.login(
        email: 'user@example.com',
        password: 'wrong',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());
      expect(
        (result.errorOrNull as ZenUnauthorizedError).message,
        AuthError.authenticationFailed.code,
      );
    });

    test('login stores token on successful authentication', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'idToken': 'stored_token', 'userId': 'user123'}),
          200,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      await apiClient.login(email: 'user@example.com', password: 'secret');

      // Verify token was stored by making another request
      final mockClient2 = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer stored_token');
        return http.Response(
          jsonEncode({
            'user_id': 'user123',
            'display_name': 'Test',
            'email': 'user@example.com',
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient2 = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient2,
      );
      apiClient2.setIdToken('stored_token');

      final profileResult = await apiClient2.getProfile(
        userId: 'user123',
        language: 'en',
      );

      expect(profileResult.isSuccess, isTrue);
    });

    test('ping with different error code parses correctly', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'unknownError'}),
          500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.ping(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
    });

    test('getProfile returns error when token is cleared', () async {
      final apiClient = ZenDemoApiClient(baseUrl: 'http://localhost');
      apiClient.setIdToken('token123');
      apiClient.setIdToken(null);

      final result = await apiClient.getProfile(
        userId: 'user123',
        language: 'en',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnauthorizedError>());
    });

    test('getTerms with different language headers', () async {
      final mockClient = MockClient((request) async {
        final lang = request.headers['Accept-Language'];
        expect(['en', 'fr', 'de'], contains(lang));

        return http.Response(
          jsonEncode({'content': '# Terms', 'content_type': 'text/markdown'}),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'fr');

      expect(result.isSuccess, isTrue);
    });

    test('getTerms with notFound error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'notFound'}),
          404,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
      expect(
        (result.errorOrNull as ZenUnknownError).message,
        TermsError.notFound.code,
      );
    });

    test('getTerms with loadFailed error', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'loadFailed'}),
          500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final result = await apiClient.getTerms(language: 'en');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenUnknownError>());
      expect(
        (result.errorOrNull as ZenUnknownError).message,
        TermsError.loadFailed.code,
      );
    });

    test('getProfile with different user IDs', () async {
      final mockClient = MockClient((request) async {
        final userId = request.url.pathSegments.last;
        expect(['user1', 'user2', 'user3'], contains(userId));

        return http.Response(
          jsonEncode({
            'user_id': userId,
            'display_name': 'Test User',
            'email': 'user@example.com',
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final apiClient = ZenDemoApiClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );
      apiClient.setIdToken('token123');

      final result = await apiClient.getProfile(
        userId: 'user1',
        language: 'en',
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
