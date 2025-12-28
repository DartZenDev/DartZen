/// Infrastructure Identity module for DartZen.
///
/// Pure infrastructure adapter that bridges external authentication systems
/// (GCP Identity Toolkit) with the DartZen Identity domain.
///
/// This package maps verified authentication facts to domain identity operations.
/// It does not authenticate users, validate credentials, or define identity semantics.
library;

export 'src/auth_claims.dart';
export 'src/identity_resolver.dart';
export 'src/l10n/infrastructure_identity_messages.dart';
