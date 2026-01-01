// ignore_for_file: avoid_print

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

/// Example demonstrating unified configuration approach for dartzen_firestore.
///
/// This example shows how the same initialization code works for both
/// production and development (emulator) environments.
Future<void> main() async {
  print('\n=== dartzen_firestore Example ===\n');

  // 1. Single configuration for both environments
  //    No need to check dzIsPrd manually - the package handles it!
  //
  //    In production (dzIsPrd = true): connects to Firestore
  //    In development (dzIsPrd = false): connects to Firestore Emulator
  final config = FirestoreConfig(projectId: 'dev-project');

  print('📋 Configuration:');
  print('   Project: ${config.projectId}');
  print(
    '   Mode: ${config.isProduction ? "PRODUCTION" : "EMULATOR (${config.emulatorHost}:${config.emulatorPort})"}',
  );
  print('');

  // 2. Initialize connection
  //    The package automatically:
  //    - Connects to appropriate service (production or emulator)
  //    - Verifies emulator availability in development mode
  try {
    await FirestoreConnection.initialize(config);
    print('✅ Connection initialized successfully\n');
  } catch (e) {
    print('❌ Failed to initialize Firestore: $e');
    print('');
    print('💡 Make sure the Firestore emulator is running:');
    print('   firebase emulators:start --only firestore');
    return;
  }

  // 3. Demonstrate basic functionality
  print('--- Type Converters ---');
  await _demonstrateConverters();

  print('\n=== Example Complete ===\n');
}

Future<void> _demonstrateConverters() async {
  // Timestamp conversion
  final zenTimestamp = ZenTimestamp.now();
  final rfc3339 = FirestoreConverters.zenTimestampToRfc3339(zenTimestamp);
  final backToZen = FirestoreConverters.rfc3339ToZenTimestamp(rfc3339);

  print('ZenTimestamp: ${zenTimestamp.value}');
  print('RFC 3339: $rfc3339');
  print('Back to ZenTimestamp: ${backToZen.value}');

  // Claims normalization
  final rawClaims = {
    'created_at': ZenTimestamp.now(),
    'name': 'Alice',
    'metadata': {
      'updated': ZenTimestamp.now(),
      'tags': ['user', 'active'],
    },
  };

  final normalized = FirestoreConverters.normalizeClaims(rawClaims);
  print('\nRaw claims (with ZenTimestamp objects):');
  print('  created_at: ${rawClaims['created_at'].runtimeType}');

  print('\nNormalized claims (ZenTimestamps → RFC 3339 strings):');
  print('  created_at: ${normalized['created_at']}');
  print('  metadata.updated: ${(normalized['metadata'] as Map)['updated']}');
}
