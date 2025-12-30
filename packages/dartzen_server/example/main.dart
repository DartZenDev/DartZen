// ignore_for_file: avoid_print, unused_local_variable

import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_server/dartzen_server.dart';

void main() async {
  // 1. Initialize localization service
  const localizationConfig = ZenLocalizationConfig();
  final localization = ZenLocalizationService(config: localizationConfig);

  // Load server module translations
  // Note: In a real app, you would load these from assets
  // For this example, the translations are in lib/src/l10n/server.en.json

  // 2. Create message accessor (available for handler implementations)
  // final messages = ServerMessages(localization, 'en');
  // Example usage in handlers:
  // final healthMessage = messages.healthOk();
  // final errorMessage = messages.errorNotFound();

  // 3. Initialize the server application
  final app = ZenServerApplication(config: const ZenServerConfig());

  // 4. Register lifecycle hooks
  app.onStartup(() {
    print('🚀 DartZen Server starting...');
    // Example: Access localized message
    // In real usage, you would load the module first:
    // await localization.loadModuleMessages('server', 'en', modulePath: 'lib/src/l10n');
    print('Example localized key: server.health.ok');
  });

  app.onShutdown(() {
    print('🛑 DartZen Server shutting down...');
  });

  // 5. Run the server
  await app.run();

  print('✅ Server listening on http://localhost:8080');
  print('🔗 Health check: http://localhost:8080/health');
  print('🔗 Terms & Conditions: http://localhost:8080/terms');
}
