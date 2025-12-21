import 'package:meta/meta.dart';

/// A coarse-grained semantic grouping of permissions.
///
/// Roles are used to simplify domain policy by grouping related capabilities
/// under a single name (e.g. 'ADMIN', 'MEMBER').
@immutable
final class Role {
  /// The unique name of the role (e.g. 'ADMIN', 'MEMBER').
  final String name;

  /// Creates a [Role] with a [name].
  const Role(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Role($name)';
}

/// A fine-grained domain permission.
///
/// Capabilities represent a specific action that an identity may be permitted
/// to perform within the domain.
@immutable
final class Capability {
  /// The unique identifier for the capability (e.g. 'can_edit_document').
  final String id;

  /// Creates a [Capability] with an [id].
  const Capability(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Capability && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Capability($id)';
}

/// Represents the authority evaluation result for an identity.
///
/// Authority encapsulates the roles and capabilities granted to an identity,
/// providing methods to query its permissions.
@immutable
final class Authority {
  /// The roles assigned to the identity.
  final Set<Role> roles;

  /// The explicit capabilities granted to the identity.
  final Set<Capability> capabilities;

  /// Creates an [Authority] context with [roles] and [capabilities].
  const Authority({this.roles = const {}, this.capabilities = const {}});

  /// Evaluates if the authority possesses the required capability.
  bool hasCapability(Capability capability) =>
      capabilities.contains(capability);

  /// Evaluates if the authority possesses any of the required roles.
  bool hasRole(Role role) => roles.contains(role);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authority &&
          runtimeType == other.runtimeType &&
          _setEquals(roles, other.roles) &&
          _setEquals(capabilities, other.capabilities);

  @override
  int get hashCode => Object.hashAll(roles) ^ Object.hashAll(capabilities);

  bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
