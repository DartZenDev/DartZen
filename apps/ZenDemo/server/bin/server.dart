import 'dart:io';

import 'package:zen_demo_server/zen_demo_server.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8888');

  // Parse Auth emulator configuration
  final authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];
  if (authHost == null || authHost.isEmpty) {
    stderr.writeln('ERROR: FIREBASE_AUTH_EMULATOR_HOST is required');
    stderr.writeln('Example: export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099');
    exit(1);
  }

  // Parse Firestore emulator configuration
  final firestoreHost = Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? 'localhost:8080';
  final hostParts = firestoreHost.split(':');
  final firestoreHostname = hostParts[0];
  final firestorePort = hostParts.length > 1 ? int.parse(hostParts[1]) : 8080;

  // Parse Storage configuration
  final storageBucket = Platform.environment['STORAGE_BUCKET'];
  if (storageBucket == null || storageBucket.isEmpty) {
    stderr.writeln('ERROR: STORAGE_BUCKET is required');
    stderr.writeln('Example: export STORAGE_BUCKET=demo-bucket');
    exit(1);
  }

  final storageHost = Platform.environment['STORAGE_HOST'];
  if (storageHost == null || storageHost.isEmpty) {
    stderr.writeln('ERROR: STORAGE_HOST is required');
    stderr.writeln('Example: export STORAGE_HOST=localhost:9199');
    exit(1);
  }

  final server = ZenDemoServer(
    port: port,
    authEmulatorHost: authHost,
    firestoreHost: firestoreHostname,
    firestorePort: firestorePort,
    storageBucket: storageBucket,
    storageHost: storageHost,
  );

  try {
    await server.initialize();
    await server.run();
  } catch (e, stackTrace) {
    stderr.writeln('FATAL ERROR: Server failed to start');
    stderr.writeln(e);
    stderr.writeln(stackTrace);
    exit(1);
  }
}
