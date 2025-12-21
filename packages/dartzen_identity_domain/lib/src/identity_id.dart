import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

/// A stable, unique domain identifier for an identity.
///
/// Wraps an opaque string ID and ensures it is not empty.
@immutable
final class IdentityId {
  /// The underlying value of the identity identifier.
  final String value;

  const IdentityId._(this.value);

  /// Creates and validates an [IdentityId].
  ///
  /// Returns a [ZenResult.err] if the [value] is empty or blank.
  static ZenResult<IdentityId> create(String value) {
    if (value.trim().isEmpty) {
      return const ZenResult.err(
        ZenValidationError('IdentityId cannot be empty'),
      );
    }
    return ZenResult.ok(IdentityId._(value));
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
