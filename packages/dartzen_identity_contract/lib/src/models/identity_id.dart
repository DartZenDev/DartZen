import 'package:meta/meta.dart';

/// A unique identifier for an identity.
///
/// Wraps a string value to provide type safety and structural validation.
@immutable
final class IdentityId {
  /// The string representation of the ID.
  final String value;

  /// Creates an [IdentityId].
  ///
  /// validation: The [value] must not be empty.
  const IdentityId(this.value)
    : assert(value.length > 0, 'IdentityId cannot be empty');

  /// Creates an [IdentityId] from a JSON string.
  factory IdentityId.fromJson(String json) => IdentityId(json);

  /// Converts this [IdentityId] to a JSON string.
  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'IdentityId($value)';
}
