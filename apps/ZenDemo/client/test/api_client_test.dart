import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zen_demo_client/src/api_client.dart';

void main() {
  group('ZenDemoApiClient', () {
    test('propagates auth error code on login', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/login');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'user@example.com');
        expect(body['password'], 'secret');

        return http.Response(
          jsonEncode({'error': AuthError.invalidCredentials.code}),
          401,
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

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenUnauthorizedError>());
      expect(
        (error as ZenUnauthorizedError).message,
        AuthError.invalidCredentials.code,
      );
    });

    test('sends Accept-Language when fetching terms', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/terms');
        expect(request.headers['Accept-Language'], 'pl');

        return http.Response(
          jsonEncode({
            'content': '# Terms',
            'content_type': 'text/markdown',
          }),
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
  });
}
