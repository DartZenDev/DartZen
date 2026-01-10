import 'dart:math';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

import '../models/telemetry_event.dart';
import 'telemetry_store.dart';

/// Firestore-backed telemetry store.
///
/// Collection: `telemetry_events` (documents contain the event fields).
class FirestoreTelemetryStore implements TelemetryStore {
  /// Firestore collection id used for storing telemetry events.
  final String collectionId;

  /// Create a [FirestoreTelemetryStore]. The store writes to [collectionId]
  /// and relies on `FirestoreConnection` from `dartzen_firestore` for
  /// emulator/production wiring.
  FirestoreTelemetryStore({this.collectionId = 'telemetry_events'});

  String _docPath(String id) => '$collectionId/$id';

  String _generateId() {
    final rnd = Random.secure();
    // Use a safe 31-bit max for `nextInt` to avoid JS shift overflow on web.
    final part = rnd.nextInt(0x7FFFFFFF).toRadixString(16);
    return '${DateTime.now().toUtc().millisecondsSinceEpoch}-$part';
  }

  @override
  Future<void> addEvent(TelemetryEvent event) async {
    if (!FirestoreConnection.isInitialized) {
      throw StateError(
        'FirestoreConnection is not initialized. Call FirestoreConnection.initialize() first.',
      );
    }

    final id = event.id ?? _generateId();
    final path = _docPath(id);

    final data = <String, dynamic>{
      'id': id,
      'name': event.name,
      'timestamp': ZenTimestamp.from(event.timestamp),
      'scope': event.scope,
      'source': event.source.name,
      if (event.userId != null) 'userId': event.userId,
      if (event.sessionId != null) 'sessionId': event.sessionId,
      if (event.correlationId != null) 'correlationId': event.correlationId,
      if (event.payload != null) 'payload': event.payload,
    };

    final batch = FirestoreBatch();
    batch.set(path, data);

    final result = await batch.commit(
      metadata: {'module': 'dartzen_telemetry'},
    );
    return result.fold((_) => Future.value(), Future.error);
  }

  Map<String, dynamic> _wrapQueryValue(dynamic value) {
    if (value is String) return {'stringValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    return {'stringValue': value.toString()};
  }

  @override
  Future<List<TelemetryEvent>> queryEvents({
    String? userId,
    String? sessionId,
    String? correlationId,
    String? scope,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    if (!FirestoreConnection.isInitialized) {
      throw StateError(
        'FirestoreConnection is not initialized. Call FirestoreConnection.initialize() first.',
      );
    }

    final fromFilters = <Map<String, dynamic>>[];

    void addEq(String field, dynamic value) {
      fromFilters.add({
        'fieldFilter': {
          'field': {'fieldPath': field},
          'op': 'EQUAL',
          'value': _wrapQueryValue(value),
        },
      });
    }

    void addRange(String field, String op, DateTime value) {
      fromFilters.add({
        'fieldFilter': {
          'field': {'fieldPath': field},
          'op': op,
          'value': _wrapQueryValue(value),
        },
      });
    }

    if (userId != null) {
      addEq('userId', userId);
    }
    if (sessionId != null) {
      addEq('sessionId', sessionId);
    }
    if (correlationId != null) {
      addEq('correlationId', correlationId);
    }
    if (scope != null) {
      addEq('scope', scope);
    }
    if (from != null) {
      addRange('timestamp', 'GREATER_THAN_OR_EQUAL', from.toUtc());
    }
    if (to != null) {
      addRange('timestamp', 'LESS_THAN_OR_EQUAL', to.toUtc());
    }

    Map<String, dynamic>? where;
    if (fromFilters.isNotEmpty) {
      if (fromFilters.length == 1) {
        where = fromFilters.first;
      } else {
        where = {
          'compositeFilter': {'op': 'AND', 'filters': fromFilters},
        };
      }
    }

    final structuredQuery = <String, dynamic>{
      'from': [
        {'collectionId': collectionId},
      ],
      if (where != null) 'where': where,
      'orderBy': [
        {
          'field': {'fieldPath': 'timestamp'},
          'direction': 'ASCENDING',
        },
      ],
      if (limit != null) 'limit': limit,
    };

    final list = await FirestoreConnection.client.runStructuredQuery(
      structuredQuery,
    );
    final results = <TelemetryEvent>[];

    for (final item in list) {
      if (item is Map<String, dynamic> && item.containsKey('document')) {
        final doc = item['document'] as Map<String, dynamic>;
        final name = doc['name'] as String? ?? '';
        final segments = name.split('/documents/');
        final path = segments.length > 1 ? segments[1] : '';
        final id = path.isNotEmpty ? path.split('/').last : null;
        final fields = doc['fields'] as Map<String, dynamic>? ?? {};
        final data = FirestoreConverters.fieldsToData(fields);

        // Normalize timestamp to ISO string
        final timestampVal = data['timestamp'];
        final tsString = timestampVal is ZenTimestamp
            ? timestampVal.value.toUtc().toIso8601String()
            : (timestampVal is DateTime
                  ? timestampVal.toUtc().toIso8601String()
                  : timestampVal?.toString());

        final jsonMap = <String, dynamic>{
          'id': id,
          'name': data['name'] ?? data['type'] ?? '',
          'timestamp': tsString,
          'scope': data['scope'],
          'source': data['source'],
          if (data['userId'] != null) 'userId': data['userId'],
          if (data['sessionId'] != null) 'sessionId': data['sessionId'],
          if (data['correlationId'] != null)
            'correlationId': data['correlationId'],
          if (data['payload'] != null) 'payload': data['payload'],
        };

        results.add(TelemetryEvent.fromJson(jsonMap));
      }
    }

    return results;
  }
}
