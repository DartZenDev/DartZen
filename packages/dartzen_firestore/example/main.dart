// ignore_for_file: avoid_print

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Example demonstrating dartzen_firestore usage with REST API.
Future<void> main() async {
  // 1. Initialize localization
  final localization = ZenLocalizationService(
    config: const ZenLocalizationConfig(isProduction: false),
  );

  // 2. Initialize Firestore connection
  const config = FirestoreConfig.emulator();

  try {
    await FirestoreConnection.initialize(config, localization: localization);
  } catch (e) {
    print('Failed to initialize Firestore: $e');
    print('Make sure the Firestore emulator is running:');
    print('  firebase emulators:start --only firestore');
    return;
  }

  print('\n=== dartzen_firestore Example (REST) ===\n');

  // 3. Type Converters Example
  await _demonstrateConverters();

  // 4. Batch Operations Example
  await _demonstrateBatch(localization);

  // 5. Transaction Example
  await _demonstrateTransaction(localization);

  // 6. Error Handling Example
  await _demonstrateErrorHandling(localization);

  print('\n=== Example Complete ===\n');
}

Future<void> _demonstrateConverters() async {
  print('--- Type Converters ---');

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
  print('');
}

Future<void> _demonstrateBatch(ZenLocalizationService localization) async {
  print('--- Batch Operations ---');

  final batch = FirestoreBatch(localization: localization);

  // Add multiple operations to the batch
  batch.set('users/user1', {
    'name': 'Alice',
    'age': 30,
    'created_at': ZenTimestamp.now(),
  });

  batch.set('users/user2', {
    'name': 'Bob',
    'age': 25,
    'created_at': ZenTimestamp.now(),
  });

  batch.update('users/user1', {'age': 31});

  // Commit the batch
  final result = await batch.commit();

  result.fold(
    (_) => print('✓ Batch committed successfully (3 operations)'),
    (error) => print('✗ Batch failed: $error'),
  );

  print('');
}

Future<void> _demonstrateTransaction(
  ZenLocalizationService localization,
) async {
  print('--- Transaction Example ---');

  // Initialize a counter
  await FirestoreConnection.client.patchDocument('counters/global', {
    'value': 0,
  });

  // Run a transaction to increment the counter
  final result = await FirestoreTransaction.run<int>((transaction) async {
    final doc = await transaction.get('counters/global');

    if (!doc.exists) {
      return const ZenResult<int>.err(ZenNotFoundError('Counter not found'));
    }

    final currentValue = doc.data?['value'] as int? ?? 0;
    final newValue = currentValue + 1;

    transaction.update('counters/global', {'value': newValue});
    return ZenResult<int>.ok(newValue);
  }, localization: localization);

  result.fold(
    (newValue) => print('✓ Transaction succeeded. Counter value: $newValue'),
    (error) => print('✗ Transaction failed: $error'),
  );

  print('');
}

Future<void> _demonstrateErrorHandling(
  ZenLocalizationService localization,
) async {
  print('--- Error Handling ---');

  try {
    final doc = await FirestoreConnection.client.getDocument('nonexistent/doc');
    if (!doc.exists) {
      print('✓ Document not found (expected)');
    }
  } catch (e, stack) {
    final messages = FirestoreMessages(localization, 'en');
    final error = FirestoreErrorMapper.mapException(e, stack, messages);
    if (error is ZenNotFoundError) {
      print('✓ Document not found (expected ZenNotFoundError)');
    } else {
      print('✗ Unexpected error: $error');
    }
  }

  print('');
}
