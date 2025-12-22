import 'package:meta/meta.dart';

import 'capability.dart';
import 'identity_id.dart';
import 'role.dart';

/// Represents the effective authority of an identity at a point in time.
///
/// Contains the identity's ID, assigned roles, and the flattened list of
/// effective capabilities.
@immutable
final class Authority {
  /// The identity this authority belongs to.
  final IdentityId identityId;

  /// The roles assigned to the identity.
  final List<Role> roles;

  /// The flattened list of all capabilities the identity possesses.
  final List<Capability> effectiveCapabilities;

  /// Creates an [Authority].
  const Authority({
    required this.identityId,
    this.roles = const [],
    this.effectiveCapabilities = const [],
  });

  /// Checks if the authority has the specified capability.
  bool hasCapability(String resource, String action) => effectiveCapabilities
      .any((c) => c.resource == resource && c.action == action);

  /// Creates an [Authority] from a JSON map.
  factory Authority.fromJson(Map<String, dynamic> json) => Authority(
    identityId: IdentityId.fromJson(json['identityId'] as String),
    roles:
        (json['roles'] as List<dynamic>?)
            ?.map((e) => Role.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    effectiveCapabilities:
        (json['effectiveCapabilities'] as List<dynamic>?)
            ?.map((e) => Capability.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  /// Converts this [Authority] to a JSON map.
  Map<String, dynamic> toJson() => {
    'identityId': identityId.toJson(),
    'roles': roles.map((r) => r.toJson()).toList(),
    'effectiveCapabilities': effectiveCapabilities
        .map((c) => c.toJson())
        .toList(),
  };

  @override
  String toString() =>
      'Authority(identity: $identityId, roles: ${roles.length}, capabilities: ${effectiveCapabilities.length})';
}
