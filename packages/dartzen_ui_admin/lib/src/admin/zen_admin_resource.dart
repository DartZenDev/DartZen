import 'package:flutter/foundation.dart';

import 'zen_admin_field.dart';
import 'zen_admin_permissions.dart';

/// Static description of an admin-managed resource.
///
/// Defines the resource name, display name, fields, and permissions.
/// Used by admin screens to render lists, forms, and action buttons.
///
/// [T] is the domain type of a single record (typically
/// `Map<String, dynamic>` when working with raw transport data).
@immutable
class ZenAdminResource<T> {
  /// The programmatic resource identifier (e.g., `'users'`).
  final String resourceName;

  /// The human-readable display name (e.g., `'Users'`).
  final String displayName;

  /// The field definitions for this resource.
  final List<ZenAdminField> fields;

  /// The permission set governing UI actions.
  final ZenAdminPermissions permissions;

  /// The field name used as the record's unique identifier.
  ///
  /// Defaults to `'id'`. Screens use this to extract the record ID
  /// for edit and delete actions.
  final String idFieldName;

  /// Creates a [ZenAdminResource].
  ///
  /// Asserts that [resourceName] is not empty and [fields] is not empty.
  /// The [fields] list is stored as an unmodifiable copy to preserve
  /// immutability.
  ZenAdminResource({
    required this.resourceName,
    required this.displayName,
    required List<ZenAdminField> fields,
    required this.permissions,
    this.idFieldName = 'id',
  }) : fields = List.unmodifiable(fields),
       assert(resourceName.isNotEmpty, 'resourceName must not be empty'),
       assert(fields.isNotEmpty, 'fields must not be empty');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenAdminResource<T> &&
        other.resourceName == resourceName &&
        other.displayName == displayName &&
        listEquals(other.fields, fields) &&
        other.permissions == permissions &&
        other.idFieldName == idFieldName;
  }

  @override
  int get hashCode => Object.hash(
    resourceName,
    displayName,
    Object.hashAll(fields),
    permissions,
    idFieldName,
  );

  @override
  String toString() =>
      'ZenAdminResource<$T>(resourceName: $resourceName, '
      'displayName: $displayName, fields: $fields, '
      'permissions: $permissions)';
}
