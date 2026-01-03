import 'package:dartzen_core/dartzen_core.dart';

import '../firestore_types.dart';

/// Static utility class for Firestore type conversions.
///
/// Provides helpers for converting between Firestore REST JSON format and DartZen types.
///
/// Firestore REST API uses specific value wrappers:
/// - `stringValue`: String
/// - `integerValue`: String (even if integer)
/// - `doubleValue`: number
/// - `booleanValue`: boolean
/// - `timestampValue`: RFC 3339 string
/// - `mapValue`: objects with `fields`
/// - `arrayValue`: objects with `values`
/// - `nullValue`: null
abstract final class FirestoreConverters {
  /// Converts a [ZenTimestamp] to RFC 3339 string for Firestore REST.
  static String zenTimestampToRfc3339(ZenTimestamp zenTimestamp) =>
      zenTimestamp.value.toUtc().toIso8601String().replaceAll('.000', '');

  /// Converts RFC 3339 string from Firestore REST to [ZenTimestamp].
  static ZenTimestamp rfc3339ToZenTimestamp(String rfc3339) =>
      ZenTimestamp.from(DateTime.parse(rfc3339));

  /// Converts Firestore REST "Fields" map to [ZenFirestoreData].
  static ZenFirestoreData fieldsToData(Map<String, dynamic> fields) {
    final data = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        data[entry.key] = _unwrapValue(value);
      } else {
        // If value is not a map (e.g. null), treat as null
        data[entry.key] = null;
      }
    }
    return data;
  }

  /// Converts [ZenFirestoreData] to Firestore REST "Fields" map.
  static Map<String, dynamic> dataToFields(ZenFirestoreData data) {
    final fields = <String, dynamic>{};
    for (final entry in data.entries) {
      // Only include fields where value is not null
      if (entry.value != null) {
        fields[entry.key] = _wrapValue(entry.value);
      }
    }
    return fields;
  }

  static dynamic _unwrapValue(Map<String, dynamic>? value) {
    if (value == null) return null;
    if (value.containsKey('stringValue')) return value['stringValue'] as String;
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'] as String);
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('timestampValue')) {
      return rfc3339ToZenTimestamp(value['timestampValue'] as String);
    }
    if (value.containsKey('mapValue')) {
      final mapVal = value['mapValue'] as Map<String, dynamic>;
      final fields = mapVal['fields'] as Map<String, dynamic>? ?? {};
      return fieldsToData(fields);
    }
    if (value.containsKey('arrayValue')) {
      final arrayVal = value['arrayValue'] as Map<String, dynamic>;
      final values = arrayVal['values'] as List<dynamic>? ?? [];
      return values
          .map((v) => _unwrapValue(v as Map<String, dynamic>))
          .toList();
    }
    if (value.containsKey('nullValue')) return null;
    return null;
  }

  static Map<String, dynamic> _wrapValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is ZenTimestamp) {
      return {'timestampValue': zenTimestampToRfc3339(value)};
    }
    if (value is DateTime) {
      return {
        'timestampValue': zenTimestampToRfc3339(ZenTimestamp.from(value)),
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {'fields': dataToFields(value)},
      };
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_wrapValue).toList()},
      };
    }
    return {'nullValue': null};
  }

  /// Normalizes claims for domain logic.
  static Map<String, dynamic> normalizeClaims(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{};
    for (final entry in raw.entries) {
      normalized[entry.key] = _normalizeValue(entry.value);
    }
    return normalized;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is ZenTimestamp) {
      return value.value.toIso8601String();
    } else if (value is Map<String, dynamic>) {
      return normalizeClaims(value);
    } else if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  /// Safely casts a dynamic value to a list of strings.
  static List<String> safeStringList(dynamic value) {
    if (value is! List) return [];
    try {
      return value.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Safely casts a dynamic value to a map.
  static Map<String, dynamic>? safeMap(dynamic value) {
    if (value is! Map) return null;
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }
}
