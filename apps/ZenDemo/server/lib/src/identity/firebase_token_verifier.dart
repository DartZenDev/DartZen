import 'dart:async';
import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

/// Verifies Firebase ID tokens.
///
/// In production, this would use the Firebase Admin SDK or verify JWTs properly.
/// For the emulator, we use a simplified verification against the emulator's endpoint.
class FirebaseTokenVerifier {
  /// Creates the verifier.
  FirebaseTokenVerifier({
    required String authEmulatorHost,
  }) : _authEmulatorHost = authEmulatorHost;

  final String _authEmulatorHost;
  final ZenLogger _logger = ZenLogger.instance;

  /// Verifies a Firebase ID token and returns the user ID.
  Future<ZenResult<Map<String, dynamic>>> verifyToken(String idToken) async {
    try {
      // For Firebase Auth Emulator, we can verify tokens using the emulator's endpoint
      final url = Uri.parse('http://$_authEmulatorHost/identitytoolkit.googleapis.com/v1/accounts:lookup?key=fake-api-key');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (response.statusCode != 200) {
        _logger.info('Token verification failed: ${response.statusCode}');
        return const ZenResult.err(
          ZenUnauthorizedError(
            'Failed to verify token',
            internalData: {'status': 'non-200'},
          ),
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>?;

      if (users == null || users.isEmpty) {
        return const ZenResult.err(
          ZenUnauthorizedError('Token verification returned no user'),
        );
      }

      final user = users.first as Map<String, dynamic>;
      final userId = user['localId'] as String;
      final email = user['email'] as String?;

      _logger.info('Token verified for user: $userId');

      return ZenResult.ok({
        'userId': userId,
        'email': email,
        'displayName': user['displayName'],
        'photoUrl': user['photoUrl'],
      });
    } catch (e, stackTrace) {
      _logger.error('Token verification error', error: e, stackTrace: stackTrace);
      return ZenResult.err(
        ZenUnknownError(
          'Failed to verify token',
          internalData: {'error': e.toString()},
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
