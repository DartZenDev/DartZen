/// Server-side authorization support for DartZen Identity.
///
/// This library provides token verification using GCP Identity Toolkit REST API.
/// It is designed for server-side use only and should not be imported by client code.
///
/// The verifier automatically switches between production and Firebase Emulator
/// based on the `dzIsPrd` constant.
///
/// Example:
/// ```dart
/// import 'package:dartzen_identity/server.dart';
///
/// final verifier = IdentityTokenVerifier(
///   config: IdentityTokenVerifierConfig(projectId: 'my-project'),
/// );
///
/// final result = await verifier.verifyToken(idToken);
/// result.fold(
///   (data) => print('User: ${data.userId}'),
///   (error) => print('Error: ${error.message}'),
/// );
/// ```
library;

export 'src/server/identity_token_verifier.dart';
