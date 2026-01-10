import 'models/telemetry_event.dart';
import 'store/telemetry_store.dart';

/// Minimal public client for emitting and querying telemetry events.
class TelemetryClient {
  final TelemetryStore _store;

  /// Create a `TelemetryClient` with a backing [TelemetryStore].
  TelemetryClient(this._store);

  /// Emit a telemetry event. The call fails if the event or store fails validation.
  Future<void> emitEvent(TelemetryEvent event) async {
    await _store.addEvent(event);
  }

  /// Query events by `userId`.
  Future<List<TelemetryEvent>> queryByUserId(String userId, {int? limit}) =>
      _store.queryEvents(userId: userId, limit: limit);

  /// Query events by `sessionId`.
  Future<List<TelemetryEvent>> queryBySessionId(
    String sessionId, {
    int? limit,
  }) => _store.queryEvents(sessionId: sessionId, limit: limit);

  /// Query events by `scope` and optional time range.
  Future<List<TelemetryEvent>> queryByScope(
    String scope, {
    DateTime? from,
    DateTime? to,
    int? limit,
  }) => _store.queryEvents(scope: scope, from: from, to: to, limit: limit);
}
