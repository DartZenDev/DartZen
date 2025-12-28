import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';

/// Static utility class for Firestore type conversions.
///
/// Provides helpers for converting between Firestore SDK types and DartZen types,
/// preventing SDK type leakage into domain layers.
abstract final class FirestoreConverters {
  /// Converts a Firestore [Timestamp] to [ZenTimestamp].
  static ZenTimestamp timestampToZenTimestamp(Timestamp timestamp) =>
      ZenTimestamp.from(timestamp.toDate());

  /// Converts a [ZenTimestamp] to Firestore [Timestamp].
  static Timestamp zenTimestampToTimestamp(ZenTimestamp zenTimestamp) =>
      Timestamp.fromMillisecondsSinceEpoch(
        zenTimestamp.value.millisecondsSinceEpoch,
      );

  /// Converts a Firestore [Timestamp] to ISO 8601 string.
  static String timestampToIso8601(Timestamp timestamp) =>
      timestamp.toDate().toIso8601String();

  /// Converts an ISO 8601 string to Firestore [Timestamp].
  ///
  /// Returns `null` if the string cannot be parsed.
  static Timestamp? iso8601ToTimestamp(String iso) {
    try {
      final dateTime = DateTime.parse(iso);
      return Timestamp.fromDate(dateTime);
    } catch (_) {
      return null;
    }
  }

  /// Normalizes Firestore claims by converting SDK types to primitives.
  ///
  /// Recursively processes nested maps and lists, converting:
  /// - [Timestamp] → ISO 8601 string
  /// - Nested maps → normalized maps
  /// - Lists → normalized lists
  ///
  /// This prevents Firestore SDK types from leaking into domain logic.
  static Map<String, dynamic> normalizeClaims(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{};

    for (final entry in raw.entries) {
      normalized[entry.key] = _normalizeValue(entry.value);
    }

    return normalized;
  }

  /// Recursively normalizes a value by converting Firestore SDK types.
  static dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return timestampToIso8601(value);
    } else if (value is Map) {
      return normalizeClaims(Map<String, dynamic>.from(value));
    } else if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  /// Safely casts a dynamic value to a list of strings.
  ///
  /// Returns an empty list if the value is not a list or contains non-string elements.
  static List<String> safeStringList(dynamic value) {
    if (value is! List) return [];

    try {
      return value.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Safely casts a dynamic value to a map.
  ///
  /// Returns `null` if the value is not a map.
  static Map<String, dynamic>? safeMap(dynamic value) {
    if (value is! Map) return null;

    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }
}
