import 'package:flutter/foundation.dart';

/// Represents a paginated result from an admin query.
///
/// [T] is the type of each item in the result set.
@immutable
class ZenAdminPage<T> {
  /// The items in the current page.
  final List<T> items;

  /// The total number of items across all pages.
  final int total;

  /// The offset used in the query that produced this page.
  final int offset;

  /// The limit used in the query that produced this page.
  final int limit;

  /// Creates a [ZenAdminPage].
  const ZenAdminPage({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZenAdminPage<T> &&
        listEquals(other.items, items) &&
        other.total == total &&
        other.offset == offset &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), total, offset, limit);

  @override
  String toString() =>
      'ZenAdminPage<$T>(items: ${items.length}, total: $total, '
      'offset: $offset, limit: $limit)';
}
