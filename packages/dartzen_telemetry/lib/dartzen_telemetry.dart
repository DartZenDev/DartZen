/// DartZen Telemetry
///
/// Semantic telemetry event tracking for the DartZen ecosystem.
///
/// This package provides a small, deterministic, Firestore-first semantic
/// event layer used by client apps, servers, and background jobs. Events are
/// persisted to Firestore (via `dartzen_firestore`) and are intended for
/// Admin Dashboard and analytics consumption.
library;

export 'src/models/telemetry_event.dart';
export 'src/store/firestore_telemetry_store.dart';
export 'src/store/telemetry_store.dart';
export 'src/telemetry_client.dart';
