import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

/// Configuration for Identity Toolkit token verification.
final class IdentityTokenVerifierConfig {
  /// The Google Cloud Project ID.
  final String projectId;

  /// The Identity Toolkit emulator host (e.g. 'localhost:9099').
  /// Only used in development mode when [dzIsPrd] is false.
  final String? emulatorHost;

  /// HTTP client for testing purposes.
  final http.Client? httpClient;

  /// Creates an [IdentityTokenVerifierConfig].
  const IdentityTokenVerifierConfig({
    required this.projectId,
    this.emulatorHost,
    this.httpClient,
  });
}

/// Verified identity information extracted from an ID token.
final class VerifiedIdentity {
  /// The unique user ID.
  final String userId;

  /// The user's email address (nullable).
  final String? email;

  /// The user's display name (nullable).
  final String? displayName;

  /// The user's photo URL (nullable).
  final String? photoUrl;

  /// Creates a [VerifiedIdentity].
  const VerifiedIdentity({
    required this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  String toString() =>
      'VerifiedIdentity(userId: $userId, email: $email, displayName: $displayName)';
}

/// Server-side token verifier using GCP Identity Toolkit REST API.
///
/// This class verifies ID tokens (JWT) issued by Firebase Auth / Identity Platform.
/// It automatically switches between production and emulator endpoints based on [dzIsPrd].
///
/// Example:
/// ```dart
/// final verifier = IdentityTokenVerifier(
///   config: IdentityTokenVerifierConfig(
///     projectId: 'my-project',
///     emulatorHost: 'localhost:9099', // only used in dev mode
///   ),
/// );
///
/// final result = await verifier.verifyToken(idToken);
/// result.fold(
///   (identity) => print('Verified: ${identity.userId}'),
///   (error) => print('Invalid token: ${error.message}'),
/// );
/// ```
final class IdentityTokenVerifier {
  final IdentityTokenVerifierConfig _config;
  late final http.Client _client;

  /// Creates an [IdentityTokenVerifier] with the given [config].
  IdentityTokenVerifier({required IdentityTokenVerifierConfig config})
    : _config = config {
    _client = config.httpClient ?? http.Client();
  }

  /// Verifies an ID token and returns verified identity information.
  ///
  /// Returns [ZenResult<VerifiedIdentity>] on success or [ZenError] on failure.
  Future<ZenResult<VerifiedIdentity>> verifyToken(String idToken) async {
    if (idToken.trim().isEmpty) {
      return const ZenResult.err(
        ZenValidationError('ID token cannot be empty'),
      );
    }

    final uri = _buildVerifyUrl();

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        return _parseVerifiedIdentity(response.body);
      } else if (response.statusCode == 400) {
        return const ZenResult.err(
          ZenUnauthorizedError('Invalid or expired ID token'),
        );
      } else {
        return ZenResult.err(
          ZenUnknownError(
            'Token verification failed: ${response.statusCode} ${response.body}',
          ),
        );
      }
    } catch (e, stack) {
      return ZenResult.err(
        ZenUnknownError(
          'Token verification error: ${e.toString()}',
          stackTrace: stack,
        ),
      );
    }
  }

  Uri _buildVerifyUrl() {
    if (dzIsPrd) {
      // Production: Google Identity Toolkit cloud endpoint
      return Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${_config.projectId}',
      );
    } else {
      // Development: Identity Toolkit Emulator
      final host = _config.emulatorHost ?? 'localhost:9099';
      return Uri.parse(
        'http://$host/identitytoolkit.googleapis.com/v1/accounts:lookup?key=${_config.projectId}',
      );
    }
  }

  ZenResult<VerifiedIdentity> _parseVerifiedIdentity(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final users = json['users'] as List<dynamic>?;

      if (users == null || users.isEmpty) {
        return const ZenResult.err(
          ZenUnauthorizedError('No user information in token response'),
        );
      }

      final user = users.first as Map<String, dynamic>;
      final userId = user['localId'] as String?;

      if (userId == null || userId.isEmpty) {
        return const ZenResult.err(
          ZenUnauthorizedError('Missing user ID in token response'),
        );
      }

      return ZenResult.ok(
        VerifiedIdentity(
          userId: userId,
          email: user['email'] as String?,
          displayName: user['displayName'] as String?,
          photoUrl: user['photoUrl'] as String?,
        ),
      );
    } catch (e, stack) {
      return ZenResult.err(
        ZenUnknownError(
          'Failed to parse token response: ${e.toString()}',
          stackTrace: stack,
        ),
      );
    }
  }

  /// Closes the HTTP client.
  void close() {
    if (_config.httpClient == null) {
      _client.close();
    }
  }
}
