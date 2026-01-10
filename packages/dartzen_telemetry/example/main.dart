// ignore_for_file: avoid_print

import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';

Future<void> main() async {
  // Initialize Firestore (will use emulator when running in dev)
  final config = FirestoreConfig(projectId: 'dev-project');
  await FirestoreConnection.initialize(config);

  final store = FirestoreTelemetryStore();
  final client = TelemetryClient(store);

  final event = TelemetryEvent(
    name: 'auth.login.success',
    timestamp: DateTime.now().toUtc(),
    scope: 'identity',
    source: TelemetrySource.client,
    userId: 'user-xyz',
    sessionId: 'session-1',
    payload: const {'method': 'otp'},
  );

  await client.emitEvent(event);

  final events = await client.queryByUserId('user-xyz');
  for (final e in events) {
    print(e);
  }
}
