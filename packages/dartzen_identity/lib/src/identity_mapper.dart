import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

import 'identity_models.dart';

/// Pure mapping between Firestore data and Identity domain models.
abstract final class IdentityMapper {
  /// Maps [ZenFirestoreData] to an [Identity] aggregate.
  static ZenResult<Identity> fromFirestore(String id, ZenFirestoreData data) {
    if (!data.containsKey('lifecycle')) {
      return const ZenResult.err(
        ZenValidationError('Missing "lifecycle" in Firestore data'),
      );
    }
    if (!data.containsKey('authority')) {
      return const ZenResult.err(
        ZenValidationError('Missing "authority" in Firestore data'),
      );
    }
    if (!data.containsKey('createdAt')) {
      return const ZenResult.err(
        ZenValidationError('Missing "createdAt" in Firestore data'),
      );
    }

    final identityId = IdentityId.reconstruct(id);
    final authorityData = data['authority'] as Map<String, dynamic>;
    final lifecycleData = data['lifecycle'] as Map<String, dynamic>;

    final roles = (authorityData['roles'] as List<dynamic>? ?? [])
        .map((e) => Role.reconstruct(e as String))
        .toSet();

    final capabilities = (authorityData['capabilities'] as List<dynamic>? ?? [])
        .map((e) => Capability.reconstruct(e as String))
        .toSet();

    final createdAt = data['createdAt'];
    if (createdAt == null) {
      return const ZenResult.err(
        ZenValidationError('Missing createdAt in Firestore data'),
      );
    }

    return ZenResult.ok(
      Identity(
        id: identityId,
        lifecycle: IdentityLifecycle.reconstruct(
          IdentityState.values.byName(
            lifecycleData['state'] as String? ?? 'pending',
          ),
          lifecycleData['reason'] as String?,
        ),
        authority: Authority(roles: roles, capabilities: capabilities),
        createdAt: ZenTimestamp.fromMilliseconds(createdAt as int),
      ),
    );
  }

  /// Maps an [Identity] aggregate to [ZenFirestoreData].
  static ZenFirestoreData toFirestore(Identity identity) => {
    'lifecycle': {
      'state': identity.lifecycle.state.name,
      if (identity.lifecycle.reason != null)
        'reason': identity.lifecycle.reason,
    },
    'authority': {
      'roles': identity.authority.roles.map((r) => r.name).toList(),
      'capabilities': identity.authority.capabilities.map((c) => c.id).toList(),
    },
    'createdAt': identity.createdAt.millisecondsSinceEpoch,
  };
}
