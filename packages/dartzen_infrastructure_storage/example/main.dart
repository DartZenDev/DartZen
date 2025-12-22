// ignore_for_file: avoid_print

import 'package:dartzen_infrastructure_storage/dartzen_infrastructure_storage.dart';
import 'package:dartzen_server/dartzen_server.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Example demonstrating explicit wiring of [GcsStaticContentProvider].
///
/// This example shows how to configure the provider and wire it into
/// the server configuration. No defaults or fallbacks are involved.
void main() async {
  // 1. Configure GCS client explicitly
  //    In production, obtain credentials from your environment
  final authClient = await auth.clientViaApplicationDefaultCredentials(
    scopes: [storage_api.StorageApi.devstorageReadOnlyScope],
  );

  final storage = Storage(authClient, 'your-gcp-project-id');

  // 2. Create the provider with explicit configuration
  final staticContentProvider = GcsStaticContentProvider(
    storage: storage,
    bucket: 'my-static-content-bucket',
    prefix: 'public/', // Optional prefix
  );

  // 3. Wire the provider into server configuration
  final config = ZenServerConfig(staticContentProvider: staticContentProvider);

  // 4. Start the server
  final app = ZenServerApplication(config: config);

  app.onStartup(() {
    print('🚀 Server starting with GCS-backed static content');
    print('📦 Bucket: my-static-content-bucket');
    print('📁 Prefix: public/');
  });

  await app.run();

  print('✅ Server listening on http://localhost:8080');
  print('🔗 Terms: http://localhost:8080/terms');
}
