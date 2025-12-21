import 'package:dartzen_identity_contract/src/models/capability.dart';
import 'package:meta/meta.dart';

/// Represents a named role containing a set of capabilities.
@immutable
final class Role {
  /// The unique identifier of the role (e.g., 'admin', 'editor').
  final String id;

  /// A human-readable name for the role.
  final String name;

  /// The list of capabilities granted by this role.
  final List<Capability> capabilities;

  /// Creates a [Role].
  const Role({
    required this.id,
    required this.name,
    this.capabilities = const [],
  });

  /// Creates a [Role] from a JSON map.
  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json['id'] as String,
    name: json['name'] as String,
    capabilities:
        (json['capabilities'] as List<dynamic>?)
            ?.map((e) => Capability.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  /// Converts this [Role] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'capabilities': capabilities.map((c) => c.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Role(id: $id, name: $name)';
}
