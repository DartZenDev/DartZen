import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

/// HTTP client for ZenDemo API.
class ZenDemoApiClient {
  /// Creates a [ZenDemoApiClient] with the given [baseUrl].
  ZenDemoApiClient({required this.baseUrl});

  /// The base URL of the ZenDemo API server.
  final String baseUrl;

  String? _idToken;

  /// Sets the ID token for authentication.
  void setIdToken(String? token) {
    _idToken = token;
  }

  /// Logs in with email and password.
  ///
  /// Returns a [ZenResult] with [LoginResponseContract] on success.
  /// On error, returns error code that should be localized on the client side.
  Future<ZenResult<LoginResponseContract>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Server returns error code, not message
        final errorCode = json['error'] as String? ?? 'unknown';
        return ZenResult.err(ZenUnauthorizedError(errorCode));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final loginResponse = LoginResponseContract.fromJson(json);

      // Store the token
      _idToken = loginResponse.idToken;

      return ZenResult.ok(loginResponse);
    } catch (e, stack) {
      return ZenResult.err(
        ZenUnknownError('network_error', stackTrace: stack),
      );
    }
  }

  /// Sends a ping request to the server.
  ///
  /// Returns a [ZenResult] with [PingContract] on success.
  Future<ZenResult<PingContract>> ping({required String language}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ping'),
        headers: {'Accept-Language': language},
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String? ?? 'unknown';
        return ZenResult.err(ZenUnknownError(errorCode));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(PingContract.fromJson(json));
    } catch (e, stack) {
      return ZenResult.err(
        ZenUnknownError('network_error', stackTrace: stack),
      );
    }
  }

  /// Gets the user profile from the server.
  ///
  /// Requires authentication. Returns a [ZenResult] with [ProfileContract] on success.
  Future<ZenResult<ProfileContract>> getProfile({
    required String userId,
    required String language,
  }) async {
    if (_idToken == null) {
      return const ZenResult.err(
        ZenUnauthorizedError('missing_auth_header'),
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Accept-Language': language,
        },
      );

      if (response.statusCode == 401) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String? ?? 'invalid_token';
        return ZenResult.err(ZenUnauthorizedError(errorCode));
      }

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String? ?? 'unknown';
        return ZenResult.err(ZenUnknownError(errorCode));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(ProfileContract.fromJson(json));
    } catch (e, stack) {
      return ZenResult.err(
        ZenUnknownError('network_error', stackTrace: stack),
      );
    }
  }

  /// Gets the terms of service from the server.
  ///
  /// Returns a [ZenResult] with [TermsContract] on success.
  Future<ZenResult<TermsContract>> getTerms({required String language}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/terms'),
        headers: {'Accept-Language': language},
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String? ?? 'unknown';
        return ZenResult.err(ZenUnknownError(errorCode));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(TermsContract.fromJson(json));
    } catch (e, stack) {
      return ZenResult.err(
        ZenUnknownError('network_error', stackTrace: stack),
      );
    }
  }
}
