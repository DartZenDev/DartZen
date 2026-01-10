import 'dart:async';

import 'package:dartzen_telemetry/src/models/telemetry_event.dart';
import 'package:dartzen_telemetry/src/store/telemetry_store.dart';

/// In-memory telemetry store used only for tests and mocks.
///
/// This is intentionally placed under `test/mocks/` and is NOT part of the
/// public package API. It exists solely as a test double for unit tests.
class InMemoryTelemetryStore implements TelemetryStore {
  final List<TelemetryEvent> _events = <TelemetryEvent>[];

  @override
  Future<void> addEvent(TelemetryEvent event) async {
    _events.add(event);
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
    final results = _events.where((e) {
      if (userId != null && e.userId != userId) return false;
      if (sessionId != null && e.sessionId != sessionId) return false;
      if (correlationId != null && e.correlationId != correlationId) {
        return false;
      }
      if (scope != null && e.scope != scope) return false;
      if (from != null && e.timestamp.isBefore(from.toUtc())) return false;
      if (to != null && e.timestamp.isAfter(to.toUtc())) return false;
      return true;
    }).toList();

    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (limit != null && limit < results.length) {
      return results.sublist(0, limit);
    }
    return results;
  }
}
