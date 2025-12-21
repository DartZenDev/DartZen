import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';
import 'package:dartzen_infrastructure_identity/src/claims_extractor.dart';
import 'package:meta/meta.dart';

/// Concrete mapper that translates external facts into domain [Identity].
///
/// This mapper is a pure translator - it extracts data from external sources
/// and passes facts to the domain. It does not make policy decisions about
/// lifecycle state or authority evaluation.
@immutable
class IdentityMapper {
  /// Creates an [IdentityMapper].
  const IdentityMapper();

  /// Maps an [ExternalIdentity] to a domain [Identity].
  ///
  /// This method translates external claims into domain primitives and
  /// delegates all policy decisions to the domain layer via
  /// [Identity.fromExternalFacts].
  ///
  /// Returns [ZenResult.err] with semantic error code if mapping fails.
  ZenResult<Identity> mapToDomain({
    required IdentityId id,
    required ExternalIdentity external,
    required ZenTimestamp createdAt,
  }) {
    try {
      // Use type-safe extractor to avoid primitive obsession
      final extractor = ClaimsExtractor(external.claims);

      // Extract roles and capabilities
      final roles = extractor.extractRoles();
      final capabilities = extractor.extractCapabilities();

      // Extract verification facts (infrastructure does not interpret these)
      final verificationFacts = IdentityVerificationFacts(
        emailVerified: extractor.isEmailVerified(),
        phoneVerified: extractor.isPhoneVerified(),
      );

      // Delegate to domain factory - domain owns the lifecycle policy
      return Identity.fromExternalFacts(
        id: id,
        authority: Authority(roles: roles, capabilities: capabilities),
        facts: verificationFacts,
        createdAt: createdAt,
      );
    } catch (e) {
      // Use semantic error code, do not expose infrastructure details
      return const ZenResult.err(
        ZenValidationError('EXTERNAL_IDENTITY_MAPPING_FAILED'),
      );
    }
  }
}
