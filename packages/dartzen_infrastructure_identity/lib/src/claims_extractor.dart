import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

/// Type-safe utility for extracting identity data from external claims.
///
/// Encapsulates the fragile claim extraction logic and provides
/// defensive type checking to prevent runtime errors.
class ClaimsExtractor {
  final Map<String, dynamic> _claims;

  /// Creates a [ClaimsExtractor] from raw claims map.
  const ClaimsExtractor(this._claims);

  /// Extracts roles from claims, returning empty set if invalid.
  Set<Role> extractRoles() {
    final roleList = _claims['roles'];
    if (roleList is! List) return {};
    return roleList.whereType<String>().map(Role.new).toSet();
  }

  /// Extracts capabilities from claims, returning empty set if invalid.
  Set<Capability> extractCapabilities() {
    final capList = _claims['capabilities'];
    if (capList is! List) return {};
    return capList.whereType<String>().map(Capability.new).toSet();
  }

  /// Checks if email is verified.
  bool isEmailVerified() => _claims['email_verified'] == true;

  /// Checks if phone is verified.
  bool isPhoneVerified() => _claims['phone_verified'] == true;
}
