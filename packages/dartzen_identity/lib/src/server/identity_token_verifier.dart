import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

/// Configuration for Identity Toolkit token verification.
final class IdentityTokenVerifierConfig {
  /// The Google Cloud Project ID.
  ///
  /// If not provided, attempts to read from [dzGcloudProjectEnvVar].
  final String? projectId;

  /// HTTP client for testing purposes.
  final http.Client? httpClient;

  /// Creates an [IdentityTokenVerifierConfig].
  ///
  /// If [projectId] is omitted, it will attempt to read `GCLOUD_PROJECT` from environment.
  ///
  /// If executing in a non-production environment (i.e. `dzIsPrd` is false),
  /// this will automatically configure for the Firebase Emulator using
  /// the host from [dzIdentityToolkitEmulatorHostEnvVar].
  factory IdentityTokenVerifierConfig({
    String? projectId,
    http.Client? httpClient,
  }) {
    final effectiveProjectId = projectId ?? dzGcloudProject;
    if (effectiveProjectId.isEmpty) {
      throw StateError(
        'Project ID must be provided via constructor or $dzGcloudProjectEnvVar environment variable.',
      );
    }

    return IdentityTokenVerifierConfig._(
      projectId: effectiveProjectId,
      httpClient: httpClient,
    );
  }

  const IdentityTokenVerifierConfig._({
    required this.projectId,
    this.httpClient,
  });
}

/// External identity data extracted from an ID token (JWT).
///
/// This is NOT a domain Identity aggregate. It represents raw claims
/// from Firebase Auth that can be used to create or lookup an Identity.
final class ExternalIdentityData {
  /// The unique user ID from Firebase Auth.
  final String userId;

  /// The user's email address (nullable).
  final String? email;

  /// Whether the email has been verified.
  final bool emailVerified;

  /// The user's display name (nullable).
  final String? displayName;

  /// The user's photo URL (nullable).
  final String? photoUrl;

  /// Creates an [ExternalIdentityData].
  const ExternalIdentityData({
    required this.userId,
    this.email,
    this.emailVerified = false,
    this.displayName,
    this.photoUrl,
  });

  @override
  String toString() =>
      'ExternalIdentityData(userId: $userId, email: $email, emailVerified: $emailVerified)';
}

/// Server-side token verifier using GCP Identity Toolkit REST API.
///
/// This class verifies ID tokens (JWT) issued by Firebase Auth.
/// It automatically switches between production and Firebase Emulator based on [dzIsPrd].
///
/// Returns [ExternalIdentityData] which contains raw claims from Firebase Auth.
/// Use this data to create or lookup a domain Identity aggregate from identity_models.
///
/// Example:
/// ```dart
/// final verifier = IdentityTokenVerifier(
///   config: IdentityTokenVerifierConfig(projectId: 'my-project'),
/// );
///
/// final result = await verifier.verifyToken(idToken);
/// result.fold(
///   (data) {
///     // Use data.userId to lookup or create Identity aggregate
///     final identityId = IdentityId.reconstruct(data.userId);
///     // ...
///   },
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

  /// Verifies an ID token and returns external identity data.
  ///
  /// Returns [ZenResult<ExternalIdentityData>] with Firebase Auth claims on success.
  Future<ZenResult<ExternalIdentityData>> verifyToken(String idToken) async {
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
      // Development: Firebase Emulator
      const host = dzIdentityToolkitEmulatorHost;
      if (host.isEmpty) {
        throw StateError(
          'Firebase Emulator host must be set via $dzIdentityToolkitEmulatorHostEnvVar in development mode.',
        );
      }
      return Uri.parse(
        'http://$host/identitytoolkit.googleapis.com/v1/accounts:lookup?key=${_config.projectId}',
      );
    }
  }

  ZenResult<ExternalIdentityData> _parseVerifiedIdentity(String responseBody) {
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
        ExternalIdentityData(
          userId: userId,
          email: user['email'] as String?,
          emailVerified: (user['emailVerified'] as bool?) ?? false,
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
