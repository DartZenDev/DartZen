// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Example demonstrating dartzen_firestore usage.
///
/// This example shows:
/// 1. Initializing Firestore connection (emulator vs production)
/// 2. Using converters for timestamp and claims normalization
/// 3. Performing batch writes
/// 4. Running transactions
/// 5. Error handling with ZenResult
Future<void> main() async {
  // 1. Initialize localization
  // In a real app, config would come from environment/settings.
  final localization = ZenLocalizationService(
    config: const ZenLocalizationConfig(isProduction: false),
  );

  // 2. Initialize Firestore connection
  // FirestoreConnection.initialize will automatically load internal Firestore module messages.
  const config = FirestoreConfig.emulator();

  try {
    await FirestoreConnection.initialize(config, localization: localization);
  } catch (e) {
    print('Failed to initialize Firestore: $e');
    print('Make sure the Firestore emulator is running:');
    print('  firebase emulators:start --only firestore');
    return;
  }

  final firestore = FirestoreConnection.instance;

  print('\n=== dartzen_firestore Example ===\n');

  // 3. Type Converters Example
  await _demonstrateConverters();

  // 4. Batch Operations Example
  await _demonstrateBatch(firestore, localization);

  // 5. Transaction Example
  await _demonstrateTransaction(firestore, localization);

  // 6. Error Handling Example
  await _demonstrateErrorHandling(firestore, localization);

  print('\n=== Example Complete ===\n');
}

Future<void> _demonstrateConverters() async {
  print('--- Type Converters ---');

  // Timestamp conversion
  final timestamp = Timestamp.now();
  final zenTimestamp = FirestoreConverters.timestampToZenTimestamp(timestamp);
  final backToTimestamp = FirestoreConverters.zenTimestampToTimestamp(
    zenTimestamp,
  );

  print('Firestore Timestamp: $timestamp');
  print('ZenTimestamp: ${zenTimestamp.value}');
  print('Back to Timestamp: $backToTimestamp');

  // Claims normalization
  final rawClaims = {
    'created_at': Timestamp.now(),
    'name': 'Alice',
    'metadata': {
      'updated': Timestamp.now(),
      'tags': ['user', 'active'],
    },
  };

  final normalized = FirestoreConverters.normalizeClaims(rawClaims);
  print('\nRaw claims (with Timestamp objects):');
  print('  created_at: ${rawClaims['created_at'].runtimeType}');

  print('\nNormalized claims (Timestamps → ISO 8601 strings):');
  print('  created_at: ${normalized['created_at']}');
  print('  metadata.updated: ${(normalized['metadata'] as Map)['updated']}');
  print('');
}

Future<void> _demonstrateBatch(
  FirebaseFirestore firestore,
  ZenLocalizationService localization,
) async {
  print('--- Batch Operations ---');

  final batch = FirestoreBatch(firestore, localization: localization);

  // Add multiple operations to the batch
  batch.set(firestore.collection('users').doc('user1'), {
    'name': 'Alice',
    'age': 30,
    'created_at': FirestoreConverters.zenTimestampToTimestamp(
      ZenTimestamp.now(),
    ),
  });

  batch.set(firestore.collection('users').doc('user2'), {
    'name': 'Bob',
    'age': 25,
    'created_at': FirestoreConverters.zenTimestampToTimestamp(
      ZenTimestamp.now(),
    ),
  });

  batch.update(firestore.collection('users').doc('user1'), {'age': 31});

  // Commit the batch
  final result = await batch.commit();

  result.fold(
    (_) => print('✓ Batch committed successfully (3 operations)'),
    (error) => print('✗ Batch failed: $error'),
  );

  print('');
}

Future<void> _demonstrateTransaction(
  FirebaseFirestore firestore,
  ZenLocalizationService localization,
) async {
  print('--- Transaction Example ---');

  // Initialize a counter
  await firestore.collection('counters').doc('global').set({'value': 0});

  // Run a transaction to increment the counter
  final result = await FirestoreTransaction.run<int>(firestore, (
    Transaction transaction,
  ) async {
    final docRef = firestore.collection('counters').doc('global');
    final snapshot = await transaction.get(docRef);

    if (!snapshot.exists) {
      return const ZenResult<int>.err(ZenNotFoundError('Counter not found'));
    }

    final currentValue = snapshot.data()?['value'] as int? ?? 0;
    final newValue = currentValue + 1;

    transaction.update(docRef, {'value': newValue});
    return ZenResult<int>.ok(newValue);
  }, localization: localization);

  result.fold(
    (newValue) => print('✓ Transaction succeeded. Counter value: $newValue'),
    (error) => print('✗ Transaction failed: $error'),
  );

  print('');
}

Future<void> _demonstrateErrorHandling(
  FirebaseFirestore firestore,
  ZenLocalizationService localization,
) async {
  print('--- Error Handling ---');

  final messages = FirestoreMessages(localization, 'en');

  // Attempt to read a non-existent document
  try {
    final snapshot = await firestore
        .collection('users')
        .doc('nonexistent')
        .get();

    if (!snapshot.exists) {
      final error = ZenNotFoundError(messages.notFound());
      print('✓ Document not found (expected): ${error.message}');
    }
  } catch (e, stack) {
    final error = FirestoreErrorMapper.mapException(e, stack, messages);
    print('✗ Unexpected error: $error');
  }

  print('');
}
