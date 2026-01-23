import 'dart:convert';

import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_jobs/src/job_store.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('JobStore Task Payload', () {
    late JobStore store;
    late MockHttpClient httpClient;

    setUp(() async {
      httpClient = MockHttpClient();
      FirestoreConnection.reset();
      await FirestoreConnection.initialize(
        FirestoreConfig(projectId: 'test'),
        httpClient: httpClient,
      );
      store = JobStore();
      registerFallbackValue(Uri());
    });

    group('setTaskPayload', () {
      test('stores task payload successfully', () async {
        final payload = {'type': 'aggregation', 'reportId': 'report-123'};

        when(
          () => httpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 200));

        final result = await store.setTaskPayload('test-job', payload);

        expect(result.isSuccess, isTrue);
      });

      test('handles empty payload', () async {
        when(
          () => httpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 200));

        final result = await store.setTaskPayload('empty-job', {});

        expect(result.isSuccess, isTrue);
      });
    });

    group('getTaskPayload', () {
      test('retrieves stored payload correctly', () async {
        final docData = {
          'name':
              'projects/test/databases/(default)/documents/jobs/retrieve-job',
          'fields': {
            'taskPayload': {
              'mapValue': {
                'fields': {
                  'taskType': {'stringValue': 'report-generation'},
                  'reportId': {'stringValue': 'rpt-456'},
                },
              },
            },
          },
        };

        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response(jsonEncode(docData), 200));

        final result = await store.getTaskPayload('retrieve-job');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNotNull);
        expect(result.dataOrNull?['taskType'], equals('report-generation'));
        expect(result.dataOrNull?['reportId'], equals('rpt-456'));
      });

      test('returns null for non-existent job', () async {
        final docData = {
          'error': {'code': 404, 'message': 'Document not found'},
        };

        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response(jsonEncode(docData), 404));

        final result = await store.getTaskPayload('non-existent-job');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });

      test('returns null for job without payload', () async {
        final docData = {
          'name':
              'projects/test/databases/(default)/documents/jobs/no-payload-job',
          'fields': {
            'enabled': {'booleanValue': true},
          },
        };

        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response(jsonEncode(docData), 200));

        final result = await store.getTaskPayload('no-payload-job');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });
    });

    group('clearTaskPayload', () {
      test('removes stored payload', () async {
        when(
          () => httpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 200));

        final result = await store.clearTaskPayload('clear-job');

        expect(result.isSuccess, isTrue);
      });
    });

    group('Round-trip serialization', () {
      test('complex payload survives round-trip', () async {
        final originalPayload = {
          'metadata': {'version': 1, 'created': '2026-01-23T10:00:00Z'},
          'sources': ['db1', 'db2'],
        };

        // Mock set
        when(
          () => httpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 200));

        // Mock get
        final docData = {
          'name':
              'projects/test/databases/(default)/documents/jobs/roundtrip-job',
          'fields': {
            'taskPayload': {
              'mapValue': {
                'fields': {
                  'metadata': {
                    'mapValue': {
                      'fields': {
                        'version': {'integerValue': '1'},
                        'created': {'stringValue': '2026-01-23T10:00:00Z'},
                      },
                    },
                  },
                  'sources': {
                    'arrayValue': {
                      'values': [
                        {'stringValue': 'db1'},
                        {'stringValue': 'db2'},
                      ],
                    },
                  },
                },
              },
            },
          },
        };

        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response(jsonEncode(docData), 200));

        // Store
        final setResult = await store.setTaskPayload(
          'roundtrip-job',
          originalPayload,
        );
        expect(setResult.isSuccess, isTrue);

        // Retrieve
        final getResult = await store.getTaskPayload('roundtrip-job');
        expect(getResult.isSuccess, isTrue);

        final retrievedPayload = getResult.dataOrNull!;
        expect(retrievedPayload['metadata'], isA<Map<dynamic, dynamic>>());
        // ignore: avoid_dynamic_calls
        expect(retrievedPayload['sources'], isA<List<dynamic>>());
        // ignore: avoid_dynamic_calls
        expect(
          (retrievedPayload['sources'] as List<dynamic>).length,
          equals(2),
        );
      });
    });

    group('Integration scenarios', () {
      test('workflow: store → retrieve → clear', () async {
        final payload = {'task': 'generate-report', 'reportType': 'monthly'};

        // Mock set
        when(
          () => httpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('{}', 200));

        // Mock get (after store)
        final docData = {
          'name':
              'projects/test/databases/(default)/documents/jobs/workflow-job',
          'fields': {
            'taskPayload': {
              'mapValue': {
                'fields': {
                  'task': {'stringValue': 'generate-report'},
                  'reportType': {'stringValue': 'monthly'},
                },
              },
            },
          },
        };

        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response(jsonEncode(docData), 200));

        // 1. Store task payload
        var result = await store.setTaskPayload('workflow-job', payload);
        expect(result.isSuccess, isTrue);

        // 2. Retrieve for processing
        final getResult = await store.getTaskPayload('workflow-job');
        expect(getResult.isSuccess, isTrue);
        expect(getResult.dataOrNull?['task'], equals('generate-report'));

        // 3. Clear payload
        result = await store.clearTaskPayload('workflow-job');
        expect(result.isSuccess, isTrue);
      });
    });
  });
}
