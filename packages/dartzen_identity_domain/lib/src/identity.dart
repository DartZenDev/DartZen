import 'package:dartzen_core/dartzen_core.dart';

import 'authority.dart';
import 'identity_id.dart';
import 'identity_lifecycle.dart';
import 'identity_verification_facts.dart';

/// The central domain aggregate representing an identity.
///
/// An Identity is stable, unique, and holds authority within the domain.
class Identity {
  /// The unique identifier for this identity.
  final IdentityId id;

  /// The current lifecycle state of the identity.
  final IdentityLifecycle lifecycle;

  /// The authority (roles and capabilities) granted to this identity.
  final Authority authority;

  /// Domain-level metadata.
  final ZenTimestamp createdAt;

  /// Creates an [Identity] aggregate.
  const Identity({
    required this.id,
    required this.lifecycle,
    required this.authority,
    required this.createdAt,
  });

  /// Factory for creating a new, pending identity.
  static Identity createPending({
    required IdentityId id,
    Authority authority = const Authority(),
  }) => Identity(
    id: id,
    lifecycle: IdentityLifecycle.initial(),
    authority: authority,
    createdAt: ZenTimestamp.now(),
  );

  /// Creates an [Identity] from external verification facts.
  ///
  /// Domain policy: Identity is activated only if email is verified.
  /// This encapsulates the business rule that email verification is
  /// sufficient for activation, keeping this decision in the domain layer.
  static ZenResult<Identity> fromExternalFacts({
    required IdentityId id,
    required Authority authority,
    required IdentityVerificationFacts facts,
    required ZenTimestamp createdAt,
  }) {
    // Domain logic: determine lifecycle based on verification facts
    var lifecycle = IdentityLifecycle.initial();
    if (facts.emailVerified) {
      final activationResult = lifecycle.activate();
      lifecycle = activationResult.fold(
        (activated) => activated,
        (_) => lifecycle, // Keep as pending if activation fails
      );
    }

    return ZenResult.ok(
      Identity(
        id: id,
        lifecycle: lifecycle,
        authority: authority,
        createdAt: createdAt,
      ),
    );
  }

  /// Evaluates if the identity is allowed to perform an action requiring a [Capability].
  ///
  /// Fails if the identity is not in the [IdentityState.active] state.
  ZenResult<bool> can(Capability capability) {
    if (!lifecycle.state.canAct) {
      return ZenResult.err(
        ZenUnauthorizedError(
          lifecycle.state == IdentityState.revoked
              ? 'Identity is revoked'
              : 'Identity is not active',
        ),
      );
    }
    return ZenResult.ok(authority.hasCapability(capability));
  }

  /// Transitions the identity to a new lifecycle state.
  Identity withLifecycle(IdentityLifecycle nextLifecycle) => Identity(
    id: id,
    lifecycle: nextLifecycle,
    authority: authority,
    createdAt: createdAt,
  );

  /// Updates the authority of the identity.
  Identity withAuthority(Authority nextAuthority) => Identity(
    id: id,
    lifecycle: lifecycle,
    authority: nextAuthority,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Identity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          lifecycle == other.lifecycle &&
          authority == other.authority &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      lifecycle.hashCode ^
      authority.hashCode ^
      createdAt.hashCode;
}
