import 'package:dartzen_telemetry/src/models/telemetry_event.dart';
import 'package:test/test.dart';

void main() {
  test('valid event constructs and serializes', () {
    final now = DateTime.utc(2022);
    final e = TelemetryEvent(
      name: 'auth.login.success',
      timestamp: now,
      scope: 'identity',
      source: TelemetrySource.server,
      userId: 'u1',
      payload: const {'k': 'v'},
    );

    final json = e.toJson();
    expect(json['name'], 'auth.login.success');
    expect(json['scope'], 'identity');
    expect(json['source'], 'server');
    expect(json['userId'], 'u1');
    expect(json['payload'], {'k': 'v'});

    final parsed = TelemetryEvent.fromJson(json);
    expect(parsed.name, e.name);
    expect(parsed.scope, e.scope);
    expect(parsed.source, e.source);
  });

  test('invalid name throws', () {
    expect(
      () => TelemetryEvent(
        name: 'not valid name!',
        timestamp: DateTime.now(),
        scope: 'identity',
        source: TelemetrySource.client,
      ),
      throwsArgumentError,
    );
  });

  test('empty scope throws', () {
    expect(
      () => TelemetryEvent(
        name: 'a.b',
        timestamp: DateTime.now(),
        scope: '',
        source: TelemetrySource.client,
      ),
      throwsArgumentError,
    );
  });

  test('fromJson throws for unknown source', () {
    final json = {
      'id': 'x',
      'name': 'a.b',
      'timestamp': '2025-01-01T00:00:00Z',
      'scope': 's',
      'source': 'nonsense',
    };

    expect(() => TelemetryEvent.fromJson(json), throwsArgumentError);
  });

  test('fromJson throws for empty name', () {
    final json = {
      'id': 'x',
      'name': '',
      'timestamp': '2025-01-01T00:00:00Z',
      'scope': 's',
      'source': 'client',
    };

    expect(() => TelemetryEvent.fromJson(json), throwsArgumentError);
  });

  test('fromJson throws for empty scope', () {
    final json = {
      'id': 'x',
      'name': 'a.b',
      'timestamp': '2025-01-01T00:00:00Z',
      'scope': '',
      'source': 'client',
    };

    expect(() => TelemetryEvent.fromJson(json), throwsArgumentError);
  });

  test('fromJson handles null payload', () {
    final json = {
      'id': 'x',
      'name': 'a.b',
      'timestamp': '2025-01-01T00:00:00Z',
      'scope': 's',
      'source': 'client',
    };

    final e = TelemetryEvent.fromJson(json);
    expect(e.payload, isNull);
  });

  test('toString contains name and source', () {
    final e = TelemetryEvent(
      name: 'x.y',
      timestamp: DateTime.utc(2022),
      scope: 's',
      source: TelemetrySource.job,
    );
    final s = e.toString();
    expect(s, contains('x.y'));
    expect(s, contains('job'));
  });

  test('TelemetrySource name values', () {
    expect(TelemetrySource.client.name, 'client');
    expect(TelemetrySource.server.name, 'server');
    expect(TelemetrySource.job.name, 'job');
  });

  test('fromJson handles all source names', () {
    for (final name in ['client', 'server', 'job']) {
      final json = {
        'id': 'x',
        'name': 'a.b',
        'timestamp': '2025-01-01T00:00:00Z',
        'scope': 's',
        'source': name,
      };

      final e = TelemetryEvent.fromJson(json);
      expect(e.source.name, name);
    }
  });

  test('toJson omits null optionals and includes when present', () {
    final e1 = TelemetryEvent(
      name: 'a.b',
      timestamp: DateTime.utc(2025),
      scope: 's',
      source: TelemetrySource.client,
    );
    final j1 = e1.toJson();
    expect(j1.containsKey('userId'), isFalse);

    final e2 = TelemetryEvent(
      id: 'id1',
      name: 'a.b',
      timestamp: DateTime.utc(2025),
      scope: 's',
      source: TelemetrySource.client,
      userId: 'u',
      sessionId: 's1',
      correlationId: 'c1',
      payload: const {'k': 1},
    );
    final j2 = e2.toJson();
    expect(j2['userId'], 'u');
    expect(j2['sessionId'], 's1');
    expect(j2['correlationId'], 'c1');
    expect(j2['payload'], {'k': 1});
  });

  test('timestamp is normalized to UTC', () {
    final local = DateTime.parse('2025-01-01T03:00:00+03:00');
    final e = TelemetryEvent(
      name: 'tz.ok',
      timestamp: local,
      scope: 's',
      source: TelemetrySource.client,
    );
    expect(e.timestamp.isUtc, isTrue);
    expect(e.timestamp.toIso8601String(), '2025-01-01T00:00:00.000Z');
  });
}
