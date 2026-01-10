import '../models/telemetry_event.dart';

/// Abstract storage/transport for telemetry events.
abstract class TelemetryStore {
  /// Persist a telemetry event. Implementations should throw on persistence failure.
  Future<void> addEvent(TelemetryEvent event);

  /// Query events with optional filters. Implementations should return a snapshot of matching events.
  Future<List<TelemetryEvent>> queryEvents({
    String? userId,
    String? sessionId,
    String? correlationId,
    String? scope,
    DateTime? from,
    DateTime? to,
    int? limit,
  });
}
