// ignore_for_file: avoid_print

import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  // 1. Initialize the server application
  final app = ZenServerApplication(config: const ZenServerConfig());

  // 2. Register lifecycle hooks
  app.onStartup(() {
    print('🚀 DartZen Server Skeleton starting...');
  });

  app.onShutdown(() {
    print('🛑 DartZen Server Skeleton shutting down...');
  });

  // 3. Run the server
  await app.run();

  print('✅ Server listening on http://localhost:8080');
  print('🔗 Health check: http://localhost:8080/health');

  print('🔗 Terms & Conditions: http://localhost:8080/terms');
}
