import 'package:dartzen_core/dartzen_core.dart';

import 'identity.dart';
import 'identity_id.dart';

/// Represents an external identity fact before it's mapped to a domain [Identity].
abstract interface class ExternalIdentity {
  /// The unique subject identifier from the IdP.
  String get subject;

  /// External claims/attributes.
  Map<String, dynamic> get claims;
}

/// Port for external Identity Providers.
abstract interface class IdentityProvider {
  /// Retrieves an [ExternalIdentity] by its [subject].
  Future<ZenResult<ExternalIdentity>> getIdentity(String subject);

  /// Resolves an [IdentityId] from an [ExternalIdentity].
  Future<ZenResult<IdentityId>> resolveId(ExternalIdentity external);
}

/// Port for identity lifecycle events and hooks.
abstract interface class IdentityHooks {
  /// Called when an identity is revoked.
  Future<ZenResult<void>> onRevoked(Identity identity, String reason);

  /// Called when an identity is suspended/disabled.
  Future<ZenResult<void>> onDisabled(Identity identity, String reason);
}

/// Port for background identity maintenance.
abstract interface class IdentityCleanup {
  /// Removes or archives identities that are expired or unverified.
  Future<ZenResult<int>> cleanupExpiredIdentities(ZenTimestamp before);
}
