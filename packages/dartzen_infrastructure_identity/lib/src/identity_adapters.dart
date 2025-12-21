import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

/// Concrete implementation of [IdentityHooks] for infrastructure logging and side-effects.
class InfrastructureIdentityHooks implements IdentityHooks {
  @override
  Future<ZenResult<void>> onRevoked(Identity identity, String reason) async =>
      const ZenResult.ok(null);

  @override
  Future<ZenResult<void>> onDisabled(Identity identity, String reason) async =>
      const ZenResult.ok(null);
}

/// Concrete implementation of [IdentityCleanup] for background maintenance.
class InfrastructureIdentityCleanup implements IdentityCleanup {
  @override
  Future<ZenResult<int>> cleanupExpiredIdentities(ZenTimestamp before) async =>
      const ZenResult.ok(0);
}
