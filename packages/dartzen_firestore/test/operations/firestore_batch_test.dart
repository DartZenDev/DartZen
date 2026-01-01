import 'dart:convert';

import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
  });

  group('FirestoreBatch', () {
    test('set and commit operations send correct REST request', () async {
      final writes = <Map<String, dynamic>>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(':commit')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          writes.addAll((body['writes'] as List).cast<Map<String, dynamic>>());
          return http.Response(
            jsonEncode({'commitTime': '2024-01-01T00:00:00Z'}),
            200,
          );
        }
        // Health check during initialize
        if (request.url.path.endsWith('_health_check')) {
          return http.Response(jsonEncode({'name': '.../_health_check'}), 200);
        }
        return http.Response('', 404);
      });

      FirestoreConnection.reset();
      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(projectId: 'test-project'),
        httpClient: mockClient,
      );

      final batch = FirestoreBatch();
      batch.set('users/1', {'name': 'Alice'});
      batch.update('users/2', {'age': 31});
      batch.delete('users/3');

      final result = await batch.commit();

      expect(result.isSuccess, isTrue);
      expect(writes, hasLength(3));

      // Verify set write
      expect((writes[0]['update'] as Map)['name'], contains('users/1'));
      expect(
        ((writes[0]['update'] as Map)['fields'] as Map)['name'],
        equals({'stringValue': 'Alice'}),
      );
      expect((writes[0]['currentDocument'] as Map)['exists'], isFalse);

      // Verify update write
      expect((writes[1]['update'] as Map)['name'], contains('users/2'));
      expect(
        ((writes[1]['update'] as Map)['fields'] as Map)['age'],
        equals({'integerValue': '31'}),
      );
      expect((writes[1]['currentDocument'] as Map)['exists'], isTrue);

      // Verify delete write
      expect(writes[2]['delete'], contains('users/3'));
    });

    test('throws error when exceeding 500 limit', () async {
      FirestoreConnection.reset();
      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(projectId: 'test-project'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('_health_check')) {
            return http.Response(
              jsonEncode({
                'name':
                    'projects/test-project/databases/(default)/documents/_health_check',
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );

      final batch = FirestoreBatch();
      for (var i = 0; i < 500; i++) {
        batch.delete('users/$i');
      }

      expect(() => batch.delete('users/extra'), throwsStateError);
    });
  });
}
