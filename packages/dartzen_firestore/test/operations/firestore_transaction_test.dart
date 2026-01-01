import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
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

        httpClient: mockClient,
      );

      final result = await FirestoreTransaction.run<int>((transaction) async {
        final doc = await transaction.get('counters/global');
        final currentValue = doc.data?['value'] as int? ?? 0;
        final newValue = currentValue + 1;

        transaction.update('counters/global', {'value': newValue});
        return ZenResult<int>.ok(newValue);
      });

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
        httpClient: mockClient,
      );

      final result = await FirestoreTransaction.run<int>(
        (transaction) async =>
            const ZenResult<int>.err(ZenNotFoundError('Not found')),
      );
      expect(result.errorOrNull, isA<ZenNotFoundError>());
    });
  });
}
