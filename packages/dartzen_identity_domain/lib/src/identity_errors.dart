import 'package:dartzen_core/dartzen_core.dart';

/// Semantic helpers for identity-related domain errors.
///
/// Use these to create standard errors for identity failures.
class IdentityErrors {
  /// Error when an identity is found but its state is revoked.
  static ZenUnauthorizedError revoked() =>
      const ZenUnauthorizedError('Identity has been revoked');

  /// Error when an identity is found but its state is pending or inactive.
  static ZenUnauthorizedError inactive() =>
      const ZenUnauthorizedError('Identity is not active');

  /// Error when an identity lacks required capabilities or roles.
  static ZenUnauthorizedError insufficientPermissions() =>
      const ZenUnauthorizedError('Insufficient permissions for this action');
}
