// ignore_for_file: avoid_print

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Example demonstrating usage of [GcsStorageReader].
///
/// This example shows how to configure the reader and fetch objects
/// from Google Cloud Storage.
void main() async {
  // 1. Configure GCS client explicitly
  //    In production, obtain credentials from your environment
  final authClient = await auth.clientViaApplicationDefaultCredentials(
    scopes: [storage_api.StorageApi.devstorageReadOnlyScope],
  );

  final storage = Storage(authClient, 'your-gcp-project-id');

  // 2. Create the storage reader with explicit configuration
  final reader = GcsStorageReader(
    storage: storage,
    bucket: 'my-content-bucket',
    prefix: 'data/', // Optional prefix
  );

  // 3. Read an object
  final object = await reader.read('document.json');

  if (object != null) {
    print('✅ Object found');
    print('📊 Size: ${object.size} bytes');
    print('📄 Content type: ${object.contentType}');
    print('📝 Content:\n${object.asString()}');
  } else {
    print('❌ Object not found');
  }

  // 4. Read another object
  final terms = await reader.read('terms.html');

  if (terms != null) {
    print('\n✅ Terms document found');
    print('📊 Size: ${terms.size} bytes');
  } else {
    print('\n❌ Terms document not found');
  }
}
