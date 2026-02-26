import 'package:meta/meta.dart';

/// Describes a single field in an admin resource.
///
/// Used by list and form screens to determine which fields to show
/// and how they should behave. All properties are immutable.
@immutable
class ZenAdminField {
  /// The programmatic name of the field (matches the data key).
  final String name;

  /// The human-readable label for the field.
  final String label;

  /// Whether this field is shown in the list/table view.
  final bool visibleInList;

  /// Whether this field can be edited in the form view.
  final bool editable;

  /// Whether this field is required when creating or editing.
  final bool required;

  /// Creates a [ZenAdminField].
  const ZenAdminField({
    required this.name,
    required this.label,
    this.visibleInList = true,
    this.editable = true,
    this.required = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenAdminField &&
        other.name == name &&
        other.label == label &&
        other.visibleInList == visibleInList &&
        other.editable == editable &&
        other.required == required;
  }

  @override
  int get hashCode =>
      Object.hash(name, label, visibleInList, editable, required);

  @override
  String toString() =>
      'ZenAdminField(name: $name, label: $label, '
      'visibleInList: $visibleInList, editable: $editable, '
      'required: $required)';
}
