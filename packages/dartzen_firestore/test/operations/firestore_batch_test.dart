import 'dart:convert';

import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalizationLoader extends ZenLocalizationLoader {
  final Map<String, String> _files = {};

  void addFile(String path, Map<String, dynamic> content) {
    _files[path] = jsonEncode(content);
  }

  @override
  Future<String> load(String path) async =>
      _files[path] ?? (throw Exception('File not found: $path'));
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ZenLocalizationService localization;
  late MockLocalizationLoader loader;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    loader = MockLocalizationLoader();
    localization = ZenLocalizationService(
      config: const ZenLocalizationConfig(isProduction: false),
      loader: loader,
    );

    loader.addFile('lib/src/l10n/firestore.en.json', {
      'firestore.error.permission_denied': 'Permission denied',
      'firestore.error.not_found': 'Document not found',
      'firestore.error.timeout': 'Operation timed out',
      'firestore.error.unavailable': 'Firestore service unavailable',
      'firestore.error.corrupted_data': 'Corrupted or invalid data',
      'firestore.error.operation_failed': 'Firestore operation failed',
      'firestore.error.unknown': 'Unknown Firestore error',
    });
  });

  group('FirestoreBatch', () {
    test('set operation adds document', () async {
      final batch = FirestoreBatch(firestore, localization: localization);
      final docRef = firestore.collection('users').doc('user1');

      batch.set(docRef, {'name': 'Alice'});
      final result = await batch.commit();

      expect(result.isSuccess, isTrue);
      final snapshot = await docRef.get();
      expect(snapshot.data()?['name'], equals('Alice'));
    });

    test('update operation modifies document', () async {
      final docRef = firestore.collection('users').doc('user1');
      await docRef.set({'name': 'Alice'});

      final batch = FirestoreBatch(firestore, localization: localization);
      batch.update(docRef, {'name': 'Bob'});
      await batch.commit();

      final snapshot = await docRef.get();
      expect(snapshot.data()?['name'], equals('Bob'));
    });
  });
}
