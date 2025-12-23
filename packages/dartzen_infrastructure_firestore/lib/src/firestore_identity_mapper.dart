import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

import 'l10n/firestore_messages.dart';
import 'models/infrastructure_errors.dart';

/// Pure function mapper between [Identity] domain aggregate and Firestore documents.
///
/// This mapper enforces the collection schema and type conversion.
/// It contains NO business logic.
class FirestoreIdentityMapper {
  final FirestoreMessages _messages;

  /// Creates a [FirestoreIdentityMapper].
  const FirestoreIdentityMapper(this._messages);

  /// Stable string tokens for lifecycle states.
  /// These tokens are persisted and must remain stable across enum renames.
  static const String _tokenPending = 'pending';
  static const String _tokenActive = 'active';
  static const String _tokenRevoked = 'revoked';
  static const String _tokenDisabled = 'disabled';

  /// Field names for Firestore documents.
  ///
  /// These field names represent the stable schema contract with Firestore.
  /// Changing these will break compatibility with existing stored documents.
  ///
  /// [_fieldLifecycleState]: Current state token (required) - see [_tokenPending], etc.
  /// [_fieldLifecycleReason]: Optional reason for state transitions (e.g., revocation reason).
  /// [_fieldRoles]: Array of role names granted to this identity.
  /// [_fieldCapabilities]: Array of capability IDs granted to this identity.
  /// [_fieldCreatedAt]: Firestore timestamp of identity creation (required for audit trail).
  static const String _fieldLifecycleState = 'lifecycle_state';
  static const String _fieldLifecycleReason = 'lifecycle_reason';
  static const String _fieldRoles = 'roles';
  static const String _fieldCapabilities = 'capabilities';
  static const String _fieldCreatedAt = 'created_at';

  /// Maps a domain [Identity] to a Firestore JSON map.
  ///
  /// Design rationale:
  /// - Uses stable tokens for lifecycle_state instead of enum.name to prevent
  ///   storage brittleness if domain enums are renamed.
  /// - lifecycle_reason is optional - only present for revoked/disabled states.
  /// - roles and capabilities are stored as simple string arrays for query efficiency.
  /// - created_at stored as Firestore Timestamp for native date queries and indexing.
  Map<String, dynamic> toMap(Identity identity) => {
    _fieldLifecycleState: _stateToToken(identity.lifecycle.state),
    if (identity.lifecycle.reason != null)
      _fieldLifecycleReason: identity.lifecycle.reason,
    _fieldRoles: identity.authority.roles.map((r) => r.name).toList(),
    _fieldCapabilities: identity.authority.capabilities
        .map((c) => c.id)
        .toList(),
    _fieldCreatedAt: Timestamp.fromMillisecondsSinceEpoch(
      identity.createdAt.value.millisecondsSinceEpoch,
    ),
  };

  /// Converts [IdentityState] to stable storage token.
  static String _stateToToken(IdentityState state) {
    switch (state) {
      case IdentityState.pending:
        return _tokenPending;
      case IdentityState.active:
        return _tokenActive;
      case IdentityState.revoked:
        return _tokenRevoked;
      case IdentityState.disabled:
        return _tokenDisabled;
    }
  }

  /// Converts stable storage token to [IdentityState].
  ZenResult<IdentityState> _tokenToState(String token) {
    switch (token) {
      case _tokenPending:
        return const ZenResult.ok(IdentityState.pending);
      case _tokenActive:
        return const ZenResult.ok(IdentityState.active);
      case _tokenRevoked:
        return const ZenResult.ok(IdentityState.revoked);
      case _tokenDisabled:
        return const ZenResult.ok(IdentityState.disabled);
      default:
        return ZenResult.err(
          ZenInfrastructureError(
            _messages.unknownLifecycleState(),
            errorCode: InfrastructureErrorCode.corruptedData,
          ),
        );
    }
  }

  /// Maps a Firestore [DocumentSnapshot] to a domain [Identity].
  ///
  /// returns [ZenResult] with [Identity] or error if mapping fails.
  ZenResult<Identity> fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) {
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.documentNotFound(),
          errorCode: InfrastructureErrorCode.corruptedData,
        ),
      );
    }

    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        return ZenResult.err(
          ZenInfrastructureError(
            _messages.documentDataNull(),
            errorCode: InfrastructureErrorCode.corruptedData,
          ),
        );
      }

      // 1. Map ID
      final idResult = IdentityId.create(doc.id);
      if (idResult.isFailure) {
        return ZenResult.err(idResult.errorOrNull!);
      }
      final id = idResult.dataOrNull!;

      // 2. Map Lifecycle (Reconstruction via replay)
      final stateStr = data[_fieldLifecycleState] as String?;
      final reason = data[_fieldLifecycleReason] as String?;

      if (stateStr == null) {
        return ZenResult.err(
          ZenInfrastructureError(
            _messages.missingLifecycleState(),
            errorCode: InfrastructureErrorCode.corruptedData,
          ),
        );
      }

      // Use stable token mapping instead of enum name lookup
      final stateResult = _tokenToState(stateStr);
      if (stateResult.isFailure) {
        return ZenResult.err(stateResult.errorOrNull!);
      }
      final targetState = stateResult.dataOrNull!;

      final lifecycleResult = _reconstructLifecycle(targetState, reason);
      if (lifecycleResult.isFailure) {
        return ZenResult.err(lifecycleResult.errorOrNull!);
      }
      final lifecycle = lifecycleResult.dataOrNull!;

      // 3. Map Authority
      final rolesList =
          (data[_fieldRoles] as List<dynamic>?)?.cast<String>() ?? [];
      final capabilitiesList =
          (data[_fieldCapabilities] as List<dynamic>?)?.cast<String>() ?? [];

      final authority = Authority(
        roles: rolesList.map(Role.new).toSet(),
        capabilities: capabilitiesList.map(Capability.new).toSet(),
      );

      // 4. Map CreatedAt
      final timestamp = data[_fieldCreatedAt] as Timestamp?;
      if (timestamp == null) {
        return ZenResult.err(
          ZenInfrastructureError(
            _messages.missingTimestamp(),
            errorCode: InfrastructureErrorCode.corruptedData,
          ),
        );
      }
      final createdAt = ZenTimestamp.from(timestamp.toDate());

      return ZenResult.ok(
        Identity(
          id: id,
          lifecycle: lifecycle,
          authority: authority,
          createdAt: createdAt,
        ),
      );
    } catch (e, stack) {
      return ZenResult.err(
        ZenInfrastructureError(
          _messages.corruptedData(),
          errorCode: InfrastructureErrorCode.corruptedData,
          originalError: e,
          stackTrace: stack,
        ),
      );
    }
  }

  /// Reconstructs [IdentityLifecycle] by replaying transitions from initial state.
  static ZenResult<IdentityLifecycle> _reconstructLifecycle(
    IdentityState targetState,
    String? reason,
  ) {
    final initial = IdentityLifecycle.initial();

    switch (targetState) {
      case IdentityState.pending:
        return ZenResult.ok(initial);

      case IdentityState.active:
        return initial.activate();

      case IdentityState.revoked:
        final r = reason ?? 'Revoked (reason missing)';
        return initial.revoke(r);

      case IdentityState.disabled:
        final r = reason ?? 'Disabled (reason missing)';
        return initial.disable(r);
    }
  }
}
