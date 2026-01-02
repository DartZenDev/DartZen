import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

/// Authentication error codes exchanged between server and client.
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
  /// Returns the string representation expected by clients.
  String get code => name;
}

/// Auth service that validates credentials and talks to Firebase Auth REST API.
class AuthService {
  /// Creates an [AuthService] using the provided Firebase Auth endpoint.
  AuthService({required this.authUrl});

  /// Firebase Auth endpoint used for sign-in.
  final Uri authUrl;

  /// Authenticates a user with email/password after validation.
  Future<ZenResult<Map<String, dynamic>>> authenticate({
    required String email,
    required String password,
  }) async {
    final validation = _validate(email: email, password: password);
    if (!validation.isSuccess) {
      return ZenResult.err(validation.errorOrNull!);
    }

    try {
      final response = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode != 200) {
        return ZenResult.err(
          ZenUnauthorizedError(AuthError.authenticationFailed.code),
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ZenResult.ok(json);
    } catch (_) {
      return ZenResult.err(
        ZenUnauthorizedError(AuthError.authenticationFailed.code),
      );
    }
  }

  /// Validates credentials before hitting the network.
  ZenResult<void> _validate({
    required String email,
    required String password,
  }) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty || !emailPattern.hasMatch(email)) {
      return ZenResult.err(
        ZenValidationError(AuthError.invalidEmailFormat.code),
      );
    }
    if (password.isEmpty) {
      return ZenResult.err(
        ZenValidationError(AuthError.invalidCredentials.code),
      );
    }
    return const ZenResult.ok(null);
  }
}
