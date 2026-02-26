import 'package:meta/meta.dart';

/// Represents a pagination query for admin list operations.
///
/// Default values: [offset] = 0, [limit] = 20.
/// Both values must be non-negative.
@immutable
class ZenAdminQuery {
  /// The number of items to skip.
  final int offset;

  /// The maximum number of items to return.
  final int limit;

  /// Creates a [ZenAdminQuery] with the given [offset] and [limit].
  ///
  /// Asserts that both values are non-negative (fail-fast in dev mode).
  const ZenAdminQuery({this.offset = 0, this.limit = 20})
    : assert(offset >= 0, 'offset must be non-negative'),
      assert(limit >= 0, 'limit must be non-negative');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenAdminQuery &&
        other.offset == offset &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(offset, limit);

  @override
  String toString() => 'ZenAdminQuery(offset: $offset, limit: $limit)';
}
