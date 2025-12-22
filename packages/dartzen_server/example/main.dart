import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  // 1. Initialize the server application
  final app = ZenServerApplication(config: const ZenServerConfig());

  // 2. Register lifecycle hooks
  app.onStartup(() {
    // ignore: avoid_print
    print('🚀 DartZen Server Skeleton starting...');
  });

  app.onShutdown(() {
    // ignore: avoid_print
    print('🛑 DartZen Server Skeleton shutting down...');
  });

  // 3. Run the server
  await app.run();

  // ignore: avoid_print
  print('✅ Server listening on http://localhost:8080');
  // ignore: avoid_print
  print('🔗 Health check: http://localhost:8080/health');
  // ignore: avoid_print
  print('🔗 Terms & Conditions: http://localhost:8080/terms');
}
