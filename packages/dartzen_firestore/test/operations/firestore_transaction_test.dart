import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

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
  late ZenLocalizationService localization;
  late MockLocalizationLoader loader;

  setUp(() async {
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
      'firestore.connection.emulator': 'Connecting to emulator...',
    });
  });

  group('FirestoreTransaction', () {
    test('successful transaction returns success result', () async {
      final writes = <Map<String, dynamic>>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('_health_check')) {
          return http.Response(jsonEncode({'name': '.../_health_check'}), 200);
        }
        if (request.url.path.endsWith(':beginTransaction')) {
          return http.Response(jsonEncode({'transaction': 'tx_123'}), 200);
        }
        if (request.url.path.endsWith('/counters/global') &&
            request.url.query.contains('transaction=tx_123')) {
          return http.Response(
            jsonEncode({
              'name': '.../counters/global',
              'fields': {
                'value': {'integerValue': '0'},
              },
              'createTime': '2024-01-01T00:00:00Z',
              'updateTime': '2024-01-01T00:00:00Z',
            }),
            200,
          );
        }
        if (request.url.path.endsWith(':commit')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['transaction'], equals('tx_123'));
          writes.addAll((body['writes'] as List).cast<Map<String, dynamic>>());
          return http.Response(
            jsonEncode({'commitTime': '2024-01-01T00:00:00Z'}),
            200,
          );
        }
        return http.Response('', 404);
      });

      FirestoreConnection.reset();
      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(projectId: 'test'),
        localization: localization,
        httpClient: mockClient,
      );

      final result = await FirestoreTransaction.run<int>((transaction) async {
        final doc = await transaction.get('counters/global');
        final currentValue = doc.data?['value'] as int? ?? 0;
        final newValue = currentValue + 1;

        transaction.update('counters/global', {'value': newValue});
        return ZenResult<int>.ok(newValue);
      }, localization: localization);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(1));
      expect(writes, hasLength(1));
      expect((writes[0]['update'] as Map)['name'], contains('counters/global'));
      expect(
        ((writes[0]['update'] as Map)['fields'] as Map)['value'],
        equals({'integerValue': '1'}),
      );
    });

    test('transaction propagates ZenResult errors', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('_health_check')) {
          return http.Response(jsonEncode({'name': '.../_health_check'}), 200);
        }
        if (request.url.path.endsWith(':beginTransaction')) {
          return http.Response(jsonEncode({'transaction': 'tx_123'}), 200);
        }
        return http.Response('', 404);
      });

      FirestoreConnection.reset();
      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(projectId: 'test'),
        localization: localization,
        httpClient: mockClient,
      );

      final result = await FirestoreTransaction.run<int>(
        (transaction) async =>
            const ZenResult<int>.err(ZenNotFoundError('Not found')),
        localization: localization,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ZenNotFoundError>());
    });
  });
}
