import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import 'identity_errors.dart';

/// Represents the stable lifecycle states of an identity.
enum IdentityState {
  /// Identity exists but is not yet fully activated.
  /// Used for identities awaiting verification or acceptance of terms.
  pending,

  /// Identity is valid and may participate in domain actions.
  active,

  /// Identity exists historically but is no longer allowed to act.
  /// Transition to this state is typically final.
  revoked,

  /// Identity is temporarily restricted from acting.
  disabled;

  /// Returns true if the identity can perform domain actions.
  bool get canAct => this == IdentityState.active;

  /// Returns true if the state is final.
  bool get isFinal => this == IdentityState.revoked;
}

/// Domain-driven lifecycle rules for identity state transitions.
@immutable
final class IdentityLifecycle {
  /// The current state of the identity.
  final IdentityState state;

  /// The reason for the current state (e.g. revocation reason).
  final String? reason;

  const IdentityLifecycle._(this.state, [this.reason]);

  /// Creates an initial [IdentityState.pending] lifecycle.
  factory IdentityLifecycle.initial() =>
      const IdentityLifecycle._(IdentityState.pending);

  /// Transitions to [IdentityState.active] state.
  ZenResult<IdentityLifecycle> activate() {
    if (state == IdentityState.revoked) {
      return ZenResult.err(IdentityErrors.revoked());
    }
    return const ZenResult.ok(IdentityLifecycle._(IdentityState.active));
  }

  /// Transitions to [IdentityState.revoked] state.
  ZenResult<IdentityLifecycle> revoke(String reason) {
    if (reason.trim().isEmpty) {
      return const ZenResult.err(
        ZenValidationError('Revocation reason cannot be empty'),
      );
    }
    return ZenResult.ok(IdentityLifecycle._(IdentityState.revoked, reason));
  }

  /// Transitions to [IdentityState.disabled] state.
  ZenResult<IdentityLifecycle> disable(String reason) {
    if (state == IdentityState.revoked) {
      return ZenResult.err(IdentityErrors.revoked());
    }
    return ZenResult.ok(IdentityLifecycle._(IdentityState.disabled, reason));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityLifecycle &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          reason == other.reason;

  @override
  int get hashCode => state.hashCode ^ reason.hashCode;
}
