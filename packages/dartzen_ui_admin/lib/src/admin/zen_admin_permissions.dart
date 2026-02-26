import 'package:meta/meta.dart';

/// Represents the permission set for an admin resource.
///
/// Each boolean flag controls visibility and access to specific
/// UI actions. Permissions are evaluated externally (e.g., from
/// the identity layer) and injected into [ZenAdminResource].
@immutable
class ZenAdminPermissions {
  /// Whether the current user can view records.
  final bool canRead;

  /// Whether the current user can create or edit records.
  final bool canWrite;

  /// Whether the current user can delete records.
  final bool canDelete;

  /// Creates a [ZenAdminPermissions] instance.
  const ZenAdminPermissions({
    this.canRead = false,
    this.canWrite = false,
    this.canDelete = false,
  });

  /// Creates a copy with the given fields replaced.
  ZenAdminPermissions copyWith({
    bool? canRead,
    bool? canWrite,
    bool? canDelete,
  }) {
    return ZenAdminPermissions(
      canRead: canRead ?? this.canRead,
      canWrite: canWrite ?? this.canWrite,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenAdminPermissions &&
        other.canRead == canRead &&
        other.canWrite == canWrite &&
        other.canDelete == canDelete;
  }

  @override
  int get hashCode => Object.hash(canRead, canWrite, canDelete);

  @override
  String toString() =>
      'ZenAdminPermissions(canRead: $canRead, canWrite: $canWrite, '
      'canDelete: $canDelete)';
}
