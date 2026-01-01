import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
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
  group('FirestoreIdentityRepository', () {
    late ZenLocalizationService localization;
    late MockLocalizationLoader loader;
    late FirestoreIdentityRepository repo;

    setUp(() async {
      loader = MockLocalizationLoader();
      localization = ZenLocalizationService(
        config: const ZenLocalizationConfig(isProduction: false),
        loader: loader,
      );

      // Register firestore and identity module messages
      loader.addFile('lib/src/l10n/firestore.en.json', {
        'firestore.connection.emulator': 'Connecting to emulator...',
        'firestore.error.not_found': 'Document not found',
      });
      loader.addFile('lib/src/l10n/identity.en.json', {});

      repo = FirestoreIdentityRepository(localization: localization);
    });

    test(
      'getIdentityById should return ZenNotFoundError if document missing',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('_health_check')) {
            return http.Response(
              jsonEncode({'name': '.../_health_check'}),
              200,
            );
          }
          return http.Response(
            '{"error": {"code": 404, "message": "Not found"}}',
            404,
          );
        });

        FirestoreConnection.reset();
        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(projectId: 'test'),
          localization: localization,
          httpClient: mockClient,
        );

        const id = IdentityId.reconstruct('missing');
        final result = await repo.getIdentityById(id);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenNotFoundError>());
      },
    );

    test('createIdentity should store identity in Firestore', () async {
      final writes = <Map<String, dynamic>>[];
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('_health_check')) {
          return http.Response(jsonEncode({'name': '.../_health_check'}), 200);
        }
        if (request.url.path.endsWith(':commit')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
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

      const id = IdentityId.reconstruct('user_1');
      final identity = Identity.createPending(id: id);

      final result = await repo.createIdentity(identity);
      expect(result.isSuccess, isTrue);

      expect(writes, hasLength(1));
      expect(
        (writes[0]['update'] as Map)['name'],
        contains('identities/user_1'),
      );
    });

    test('suspendIdentity should update lifecycle in Firestore', () async {
      var patched = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('_health_check')) {
          return http.Response(jsonEncode({'name': '.../_health_check'}), 200);
        }
        if (request.method == 'PATCH' &&
            request.url.path.contains('identities/user_1')) {
          patched = true;
          return http.Response(jsonEncode({'name': '.../user_1'}), 200);
        }
        return http.Response('', 404);
      });

      FirestoreConnection.reset();
      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(projectId: 'test'),
        localization: localization,
        httpClient: mockClient,
      );

      const id = IdentityId.reconstruct('user_1');
      final result = await repo.suspendIdentity(id, 'Rule violation');

      expect(result.isSuccess, isTrue);
      expect(patched, isTrue);
    });
  });
}
