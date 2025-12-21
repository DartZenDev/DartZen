import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

import 'models/infrastructure_errors.dart';

/// Pure function mapper between [Identity] domain aggregate and Firestore documents.
///
/// This mapper enforces the collection schema and type conversion.
/// It contains NO business logic.
class FirestoreIdentityMapper {
  /// Field names for Firestore documents.
  static const String _fieldLifecycleState = 'lifecycle_state';
  static const String _fieldLifecycleReason = 'lifecycle_reason';
  static const String _fieldRoles = 'roles';
  static const String _fieldCapabilities = 'capabilities';
  static const String _fieldCreatedAt = 'created_at';

  /// Maps a domain [Identity] to a Firestore JSON map.
  static Map<String, dynamic> toMap(Identity identity) => {
    _fieldLifecycleState: identity.lifecycle.state.name,
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

  /// Maps a Firestore [DocumentSnapshot] to a domain [Identity].
  ///
  /// returns [ZenResult] with [Identity] or error if mapping fails.
  static ZenResult<Identity> fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) {
      return ZenResult.err(
        ZenInfrastructureError('Document does not exist: ${doc.id}'),
      );
    }

    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        return ZenResult.err(
          ZenInfrastructureError('Document data is null: ${doc.id}'),
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
            'Missing lifecycle state in document: ${doc.id}',
          ),
        );
      }

      final targetState = IdentityState.values.firstWhere(
        (e) => e.name == stateStr,
        orElse: () => IdentityState.pending,
      );

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
          ZenInfrastructureError('Missing created_at in document: ${doc.id}'),
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
          'Failed to map identity from document',
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
