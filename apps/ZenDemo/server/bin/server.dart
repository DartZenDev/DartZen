import 'dart:io';

import 'package:zen_demo_server/zen_demo_server.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8888');

  // Parse Auth emulator configuration
  final authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];
  if (authHost == null || authHost.isEmpty) {
    stderr.writeln('ERROR: FIREBASE_AUTH_EMULATOR_HOST is required');
    stderr
        .writeln('Example: export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099');
    exit(1);
  }

  // Parse Storage configuration
  final storageBucket = Platform.environment['STORAGE_BUCKET'];
  if (storageBucket == null || storageBucket.isEmpty) {
    stderr.writeln('ERROR: STORAGE_BUCKET is required');
    stderr.writeln('Example: export STORAGE_BUCKET=demo-bucket');
    exit(1);
  }

  final server = ZenDemoServer(
    port: port,
    authEmulatorHost: authHost,
    storageBucket: storageBucket,
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
