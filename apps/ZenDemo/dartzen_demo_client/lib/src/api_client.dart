import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_demo_contracts/dartzen_demo_contracts.dart';
import 'package:http/http.dart' as http;

/// Authentication error codes shared with the server.
enum AuthError {
  /// Missing Authorization header.
  missingAuthHeader,

  /// Provided token is invalid or expired.
  invalidToken,

  /// Authentication failed at the identity provider.
  authenticationFailed,

  /// Credentials are missing or blank.
  invalidCredentials,

  /// Email format is invalid.
  invalidEmailFormat,
}

/// String codes for [AuthError].
extension AuthErrorCode on AuthError {
  /// Returns the string representation expected by the server.
  String get code => name;
}

/// Terms retrieval error codes shared with the server.
enum TermsError {
  /// Terms file missing in storage.
  notFound,

  /// Failed to load or decode terms content.
  loadFailed,
}

/// String codes for [TermsError].
extension TermsErrorCode on TermsError {
  /// Returns the string representation expected by the server.
  String get code => name;
}

/// HTTP client for ZenDemo API.
class ZenDemoApiClient {
  /// Creates a [ZenDemoApiClient] with the given [baseUrl].
  ///
  /// Optionally accepts an [httpClient] for testing.
  ZenDemoApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// The base URL of the ZenDemo API server.
  final String baseUrl;

  final http.Client _httpClient;

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
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String?;
        final error = _parseAuthError(errorCode);
        return ZenResult.err(ZenUnauthorizedError(error.code));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final loginResponse = LoginResponseContract.fromJson(json);

      // Store the token
      _idToken = loginResponse.idToken;

      return ZenResult.ok(loginResponse);
    } catch (e, stack) {
      return ZenResult.err(ZenUnknownError('network_error', stackTrace: stack));
    }
  }

  /// Sends a ping request to the server.
  ///
  /// Returns a [ZenResult] with [PingContract] on success.
  Future<ZenResult<PingContract>> ping({required String language}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/ping'),
        headers: {'Accept-Language': language},
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String?;
        final error = _parseAuthError(errorCode);
        return ZenResult.err(ZenUnknownError(error.code));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(PingContract.fromJson(json));
    } catch (e, stack) {
      return ZenResult.err(ZenUnknownError('network_error', stackTrace: stack));
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
      return const ZenResult.err(ZenUnauthorizedError('missing_auth_header'));
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Accept-Language': language,
        },
      );

      if (response.statusCode == 401) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String?;
        final error = _parseAuthError(errorCode);
        return ZenResult.err(ZenUnauthorizedError(error.code));
      }

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String?;
        final error = _parseAuthError(errorCode);
        return ZenResult.err(ZenUnknownError(error.code));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(ProfileContract.fromJson(json));
    } catch (e, stack) {
      return ZenResult.err(ZenUnknownError('network_error', stackTrace: stack));
    }
  }

  /// Gets the terms of service from the server.
  ///
  /// Returns a [ZenResult] with [TermsContract] on success.
  Future<ZenResult<TermsContract>> getTerms({required String language}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/terms'),
        headers: {'Accept-Language': language},
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = json['error'] as String?;
        final error = _parseTermsError(errorCode);
        return ZenResult.err(ZenUnknownError(error.code));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(TermsContract.fromJson(json));
    } catch (e, stack) {
      return ZenResult.err(ZenUnknownError('network_error', stackTrace: stack));
    }
  }

  /// Disposes the underlying HTTP client when it is owned by this instance.
  void close() => _httpClient.close();
}

AuthError _parseAuthError(String? code) => AuthError.values.firstWhere(
  (e) => e.code == (code ?? ''),
  orElse: () => AuthError.authenticationFailed,
);

TermsError _parseTermsError(String? code) => TermsError.values.firstWhere(
  (e) => e.code == (code ?? ''),
  orElse: () => TermsError.loadFailed,
);
