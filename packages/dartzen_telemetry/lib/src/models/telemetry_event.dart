import 'package:meta/meta.dart';

/// Represents a semantic telemetry event.
@immutable
class TelemetryEvent {
  /// Optional Firestore document id.
  final String? id;

  /// Dot-notation event name, e.g. `auth.login.success`.
  final String name;

  /// UTC timestamp of the event.
  final DateTime timestamp;

  /// Logical scope, e.g. `identity`, `payments`.
  final String scope;

  /// Source of the event.
  final TelemetrySource source;

  /// Optional user id associated with the event.
  final String? userId;

  /// Optional session id.
  final String? sessionId;

  /// Optional correlation id.
  final String? correlationId;

  /// Optional structured payload.
  final Map<String, dynamic>? payload;

  /// Creates a new [TelemetryEvent]. The constructor validates the event
  /// `name` and `scope` and normalizes `timestamp` to UTC.
  TelemetryEvent({
    this.id,
    required this.name,
    required DateTime timestamp,
    required this.scope,
    required this.source,
    this.userId,
    this.sessionId,
    this.correlationId,
    this.payload,
  }) : timestamp = timestamp.toUtc() {
    _validateName(name);
    _validateScope(scope);
  }

  static final _nameRegExp = RegExp(r'^[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+)*$');

  static void _validateName(String n) {
    if (n.isEmpty) {
      throw ArgumentError('Telemetry event name must not be empty');
    }
    if (!_nameRegExp.hasMatch(n)) {
      throw ArgumentError(
        'Telemetry event name must be dot-notation alphanumeric',
      );
    }
  }

  static void _validateScope(String s) {
    if (s.isEmpty) {
      throw ArgumentError('Telemetry scope must not be empty');
    }
  }

  /// Convert to JSON suitable for Firestore persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'scope': scope,
    'source': source.name,
    if (userId != null) 'userId': userId,
    if (sessionId != null) 'sessionId': sessionId,
    if (correlationId != null) 'correlationId': correlationId,
    if (payload != null) 'payload': payload,
  };

  /// Create an instance from JSON.
  factory TelemetryEvent.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String? ?? '';
    final ts = json['timestamp'] as String? ?? '';
    final scope = json['scope'] as String? ?? '';
    final sourceStr = json['source'] as String? ?? '';

    if (name.isEmpty) {
      throw ArgumentError('Telemetry event name missing');
    }
    if (scope.isEmpty) {
      throw ArgumentError('Telemetry scope missing');
    }
    if (ts.isEmpty) {
      throw ArgumentError('Telemetry timestamp missing or invalid');
    }

    DateTime timestamp;
    try {
      timestamp = DateTime.parse(ts).toUtc();
    } catch (e) {
      throw ArgumentError('Telemetry timestamp malformed: $ts');
    }

    final source = TelemetrySource.fromName(sourceStr);

    return TelemetryEvent(
      id: id,
      name: name,
      timestamp: timestamp,
      scope: scope,
      source: source,
      userId: json['userId'] as String?,
      sessionId: json['sessionId'] as String?,
      correlationId: json['correlationId'] as String?,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  String toString() =>
      'TelemetryEvent(name: $name, timestamp: $timestamp, scope: $scope, source: ${source.name})';
}

/// Enum for telemetry source. Use `fromName` to parse string values.
enum TelemetrySource {
  /// Event emitted by client applications.
  client,

  /// Event emitted by server-side processes.
  server,

  /// Event emitted by background jobs or workers.
  job;

  /// String representation used for persistence.
  String get name {
    switch (this) {
      case TelemetrySource.client:
        return 'client';
      case TelemetrySource.server:
        return 'server';
      case TelemetrySource.job:
        return 'job';
    }
  }

  /// Parse a persisted string into a [TelemetrySource].
  static TelemetrySource fromName(String name) {
    switch (name) {
      case 'client':
        return TelemetrySource.client;
      case 'server':
        return TelemetrySource.server;
      case 'job':
        return TelemetrySource.job;
      default:
        throw ArgumentError('Unknown TelemetrySource name: $name');
    }
  }
}
