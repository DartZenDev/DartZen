import 'dart:convert';

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
      'firestore.connection.emulator_unavailable': 'Emulator unavailable',
    });
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
        localization: localization,
        httpClient: mockClient,
      );

      final batch = FirestoreBatch(localization: localization);
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
        localization: localization,
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

      final batch = FirestoreBatch(localization: localization);
      for (var i = 0; i < 500; i++) {
        batch.delete('users/$i');
      }

      expect(() => batch.delete('users/extra'), throwsStateError);
    });
  });
}
