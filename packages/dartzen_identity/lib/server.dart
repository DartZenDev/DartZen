/// Server-side authorization support for DartZen Identity.
///
/// This library provides token verification using GCP Identity Toolkit REST API.
/// It is designed for server-side use only and should not be imported by client code.
///
/// Example:
/// ```dart
/// import 'package:dartzen_identity/server.dart';
///
/// final verifier = IdentityTokenVerifier(
///   config: IdentityTokenVerifierConfig(
///     projectId: 'my-project',
///     emulatorHost: 'localhost:9099',
///   ),
/// );
///
/// final result = await verifier.verifyToken(idToken);
/// result.fold(
///   (identity) => print('User: ${identity.userId}'),
///   (error) => print('Error: ${error.message}'),
/// );
/// ```
library;

export 'src/server/identity_token_verifier.dart';
