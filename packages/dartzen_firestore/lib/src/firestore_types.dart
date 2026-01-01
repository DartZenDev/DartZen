import 'package:dartzen_core/dartzen_core.dart';

/// Type alias for Firestore document data.
typedef ZenFirestoreData = Map<String, dynamic>;

/// Represents a Firestore document snapshot.
///
/// Replaced `cloud_firestore`'s `DocumentSnapshot` with a pure Dart implementation.
final class ZenFirestoreDocument {
  /// The document ID.
  final String id;

  /// The full document path.
  final String path;

  /// The document data.
  final ZenFirestoreData? data;

  /// The time at which the document was created.
  final ZenTimestamp? createTime;

  /// The time at which the document was last changed.
  final ZenTimestamp? updateTime;

  /// Creates a [ZenFirestoreDocument].
  const ZenFirestoreDocument({
    required this.id,
    required this.path,
    this.data,
    this.createTime,
    this.updateTime,
  });

  /// Whether the document exists.
  bool get exists => data != null;
}
