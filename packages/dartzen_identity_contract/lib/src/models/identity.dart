import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

import 'authority.dart';
import 'identity_id.dart';
import 'identity_lifecycle.dart';

/// A serializable model representing an identity.
///
/// This is a pure data contract used for transport and shared between layers.
@immutable
final class IdentityModel {
  /// The unique identifier for this identity.
  final IdentityId id;

  /// The current lifecycle state of the identity.
  final IdentityLifecycleState lifecycle;

  /// The authority (roles and capabilities) granted to this identity.
  final Authority authority;

  /// When the identity was created.
  final ZenTimestamp createdAt;

  /// Creates an [IdentityModel].
  const IdentityModel({
    required this.id,
    required this.lifecycle,
    required this.authority,
    required this.createdAt,
  });

  /// Creates an [IdentityModel] from JSON.
  factory IdentityModel.fromJson(Map<String, dynamic> json) => IdentityModel(
    id: IdentityId.fromJson(json['id'] as String),
    lifecycle: IdentityLifecycleState.fromJson(json['lifecycle'] as String),
    authority: Authority.fromJson(json['authority'] as Map<String, dynamic>),
    createdAt: ZenTimestamp.fromMilliseconds(json['createdAt'] as int),
  );

  /// Converts this [IdentityModel] to JSON.
  Map<String, dynamic> toJson() => {
    'id': id.toJson(),
    'lifecycle': lifecycle.toJson(),
    'authority': authority.toJson(),
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
