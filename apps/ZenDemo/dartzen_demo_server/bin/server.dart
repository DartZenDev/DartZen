import 'dart:io';

import 'package:dartzen_demo_server/dartzen_demo_server.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8888');

  // Parse Storage configuration
  final storageBucket = Platform.environment['STORAGE_BUCKET'];
  if (storageBucket == null || storageBucket.isEmpty) {
    stderr.writeln('ERROR: STORAGE_BUCKET is required');
    stderr.writeln('Example: export STORAGE_BUCKET=demo-bucket');
    exit(1);
  }

  final server = DartzenDemoServer(port: port, storageBucket: storageBucket);

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
