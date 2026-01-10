import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:test/test.dart';

import 'mocks/in_memory_telemetry_store.dart';

void main() {
  test('emit and query using InMemoryTelemetryStore', () async {
    final store = InMemoryTelemetryStore();
    final client = TelemetryClient(store);

    final e1 = TelemetryEvent(
      name: 'auth.login.success',
      timestamp: DateTime.utc(2022, 1, 1, 12),
      scope: 'identity',
      source: TelemetrySource.client,
      userId: 'user-1',
      sessionId: 's1',
    );

    final e2 = TelemetryEvent(
      name: 'auth.logout',
      timestamp: DateTime.utc(2022, 1, 1, 13),
      scope: 'identity',
      source: TelemetrySource.client,
      userId: 'user-2',
      sessionId: 's2',
    );

    await client.emitEvent(e1);
    await client.emitEvent(e2);

    final byUser1 = await client.queryByUserId('user-1');
    expect(byUser1.length, 1);
    expect(byUser1.first.name, 'auth.login.success');

    final bySession = await client.queryBySessionId('s2');
    expect(bySession.length, 1);
    expect(bySession.first.name, 'auth.logout');

    final byScope = await client.queryByScope('identity');
    expect(byScope.length, 2);
  });
}
