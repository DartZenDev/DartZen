import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
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

  group('FirestoreTransaction', () {
    test('successful transaction returns success result', () async {
      await firestore.collection('counters').doc('global').set({'value': 0});

      final result = await FirestoreTransaction.run<int>(firestore, (
        Transaction transaction,
      ) async {
        final docRef = firestore.collection('counters').doc('global');
        final snapshot = await transaction.get(docRef);

        final currentValue = snapshot.data()?['value'] as int? ?? 0;
        final newValue = currentValue + 1;

        transaction.update(docRef, {'value': newValue});
        return ZenResult<int>.ok(newValue);
      }, localization: localization);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(1));
    });

    test('transaction propagates ZenResult errors', () async {
      final result = await FirestoreTransaction.run<int>(
        firestore,
        (_) async => const ZenResult<int>.err(ZenNotFoundError('Not found')),
        localization: localization,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenNotFoundError>());
    });

    test('transaction handles exceptions and converts to ZenError', () async {
      final result = await FirestoreTransaction.run<int>(firestore, (_) async {
        throw Exception('Unexpected');
      }, localization: localization);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenError>());
    });
  });
}
