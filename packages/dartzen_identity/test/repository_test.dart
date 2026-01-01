import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreIdentityRepository', () {
    late FirestoreIdentityRepository repo;

    setUp(() async {
      repo = const FirestoreIdentityRepository();
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
        httpClient: mockClient,
      );

      const id = IdentityId.reconstruct('user_1');
      final result = await repo.suspendIdentity(id, 'Rule violation');

      expect(result.isSuccess, isTrue);
      expect(patched, isTrue);
    });
  });
}
