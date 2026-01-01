// ignore_for_file: avoid_print

import 'package:dartzen_storage/dartzen_storage.dart';

/// Example demonstrating unified configuration approach for [GcsStorageReader].
///
/// This example shows how the same configuration works for both
/// production and development (emulator) environments.
///
/// The package automatically:
/// - Connects to GCS in production (dzIsPrd = true)
/// - Connects to Storage Emulator in development (dzIsPrd = false)
void main() async {
  print('=== dartzen_storage Example ===\n');

  // 1. Single configuration for both environments
  //    No need to check dzIsPrd manually - the package handles it!
  final config = GcsStorageConfig(
    projectId: 'test-project', // or read from GCLOUD_PROJECT env var
    bucket: 'demo-bucket',
    prefix: 'legal/', // Optional prefix for all keys
  );

  print('📋 Configuration:');
  print('   Project: ${config.projectId}');
  print('   Bucket: ${config.bucket}');
  print('   Prefix: ${config.prefix ?? "(none)"}');
  print(
    '   Mode: ${config.emulatorHost != null ? "EMULATOR (${config.emulatorHost})" : "PRODUCTION"}',
  );
  print('');

  // 2. Create the storage reader
  //    The reader automatically handles:
  //    - Authentication (ADC in production, anonymous in emulator)
  //    - Emulator connection (if in development mode)
  //    - Runtime availability check (for emulator)
  final reader = GcsStorageReader(config: config);

  try {
    // 3. Read an object
    print('📖 Reading "terms.html"...');
    final terms = await reader.read('terms.html');

    if (terms != null) {
      print('✅ Document found');
      print('   Size: ${terms.size} bytes');
      print('   Content type: ${terms.contentType ?? "(unknown)"}');

      // Print first 200 characters of content
      final content = terms.asString();
      final preview = content.length > 200
          ? '${content.substring(0, 200)}...'
          : content;
      print('   Preview: $preview');
    } else {
      print('❌ Document not found');
    }
  } catch (e) {
    print('❌ Error: $e');
    print('');
    print('💡 Make sure the Storage emulator is running:');
    print('   firebase emulators:start --only storage');
  }

  print('');
  print('=== Example Complete ===');
}
