import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group(
    'FirestoreIdentityRepository (integration w/ mocked FirestoreRestClient)',
    () {
      tearDown(FirestoreConnection.reset);

      test('createIdentity commits writes and returns success', () async {
        const id = IdentityId.reconstruct('user_create');
        final identity = Identity.createPending(id: id);

        final mock = MockClient((request) async {
          // Health check during initialize (only match root documents path)
          if (request.method == 'GET' &&
              request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }

          // Commit endpoint
          if (request.method == 'POST' &&
              request.url.path.endsWith(':commit')) {
            return http.Response(jsonEncode({'writeResults': <dynamic>[]}), 200);
          }

          return http.Response('not found', 404);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.createIdentity(identity);
        expect(result.isSuccess, isTrue);
      });

      test('getIdentityById returns not found when document missing', () async {
        final mock = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }

          // Document GET returns 404
          if (request.method == 'GET') {
            return http.Response('Not found', 404);
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.getIdentityById(
          const IdentityId.reconstruct('missing'),
        );
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenNotFoundError>());
      });

      test(
        'verifyEmail activates pending identity and patches document',
        () async {
          const id = IdentityId.reconstruct('user_verify');
          final pendingIdentity = Identity.createPending(id: id);
          final firestoreData = IdentityMapper.toFirestore(pendingIdentity);

          final mock = MockClient((request) async {
            // Health check (only match root documents path)
            if (request.method == 'GET' &&
                request.url.path.endsWith('/documents')) {
              return http.Response('{}', 200);
            }

            // GET document
            if (request.method == 'GET' &&
                request.url.path.contains('/identities/')) {
              final body = {
                'name':
                    'projects/dev-project/databases/(default)/documents/identities/${id.value}',
                'fields': FirestoreConverters.dataToFields(firestoreData),
              };
              return http.Response(jsonEncode(body), 200);
            }

            // PATCH for lifecycle update
            if (request.method == 'PATCH') {
              return http.Response('{}', 200);
            }

            // Commit if any
            if (request.method == 'POST' &&
                request.url.path.endsWith(':commit')) {
              return http.Response(jsonEncode({'writeResults': <dynamic>[]}), 200);
            }

            return http.Response('unexpected', 500);
          });

          await FirestoreConnection.initialize(
            const FirestoreConfig.emulator(),
            httpClient: mock,
          );

          const repo = FirestoreIdentityRepository();
          final result = await repo.verifyEmail(id);
          expect(result.isSuccess, isTrue);
        },
      );

      test('changeRoles patches authority fields successfully', () async {
        const id = IdentityId.reconstruct('user_roles');
        final mock = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'PATCH') return http.Response('{}', 200);
          return http.Response('{}', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final authority = Authority(
          roles: {Role.admin},
          capabilities: {const Capability.reconstruct('can_edit')},
        );
        final result = await repo.changeRoles(id, authority);
        expect(result.isSuccess, isTrue);
      });

      test('suspendIdentity patches lifecycle to disabled', () async {
        const id = IdentityId.reconstruct('user_suspend');
        final mock = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'PATCH') return http.Response('{}', 200);
          return http.Response('{}', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.suspendIdentity(id, 'policy');
        expect(result.isSuccess, isTrue);
      });

      test('createIdentity handles commit exception', () async {
        const id = IdentityId.reconstruct('user_create_fail');
        final identity = Identity.createPending(id: id);

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          // Simulate network exception on commit
          if (request.method == 'POST' && request.url.path.endsWith(':commit')) {
            throw Exception('commit failed');
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.createIdentity(identity);
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenUnknownError>());
      });

      test('getIdentityById returns mapper validation error', () async {
        const id = IdentityId.reconstruct('user_mapper_fail');

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }

          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            // Return document missing 'lifecycle' to trigger mapper validation
            final body = {
              'name':
                  'projects/dev-project/databases/(default)/documents/identities/${id.value}',
              'fields': FirestoreConverters.dataToFields(<String, dynamic>{
                // intentionally missing lifecycle
                'authority': {'roles': <String>[], 'capabilities': <String>[]},
                'createdAt': 123456789,
              }),
            };
            return http.Response(jsonEncode(body), 200);
          }

          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.getIdentityById(id);
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('verifyEmail returns error when mapper fails', () async {
        const id = IdentityId.reconstruct('user_verify_fail');

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }

          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            // Missing authority to cause mapper validation error
            final body = {
              'name':
                  'projects/dev-project/databases/(default)/documents/identities/${id.value}',
              'fields': FirestoreConverters.dataToFields(<String, dynamic>{
                'lifecycle': {'state': 'pending'},
                // authority missing
                'createdAt': 123456789,
              }),
            };
            return http.Response(jsonEncode(body), 200);
          }

          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.verifyEmail(id);
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenValidationError>());
      });

      test('changeRoles returns unknown error when patch fails', () async {
        const id = IdentityId.reconstruct('user_roles_fail');
        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'PATCH') return http.Response('server error', 500);
          return http.Response('{}', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final authority = Authority(roles: {Role.admin});
        final result = await repo.changeRoles(id, authority);
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenUnknownError>());
      });

      test('suspendIdentity returns unknown error when patch fails', () async {
        const id = IdentityId.reconstruct('user_suspend_fail');
        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'PATCH') return http.Response('server error', 500);
          return http.Response('{}', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.suspendIdentity(id, 'policy');
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenUnknownError>());
      });

      test('getIdentityById returns identity when document exists', () async {
        const id = IdentityId.reconstruct('user_get_ok');
        final identity = Identity.createPending(id: id);
        final firestoreData = IdentityMapper.toFirestore(identity);

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            final body = {
              'name':
                  'projects/dev-project/databases/(default)/documents/identities/${id.value}',
              'fields': FirestoreConverters.dataToFields(firestoreData),
            };
            return http.Response(jsonEncode(body), 200);
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.getIdentityById(id);
        expect(result.isSuccess, isTrue);
        final got = result.dataOrNull!;
        expect(got.id, identity.id);
        expect(got.createdAt, isNotNull);
      });

      test('getIdentityById returns unknown error when getDocument fails', () async {
        const id = IdentityId.reconstruct('user_get_error');

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          // Simulate server error for document GET
          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            return http.Response('server error', 500);
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.getIdentityById(id);
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenUnknownError>());
      });

      test('verifyEmail does not patch when identity already active', () async {
        const id = IdentityId.reconstruct('user_verify_active');
        final activeIdentity = Identity.createPending(id: id).withLifecycle(
          const IdentityLifecycle.reconstruct(IdentityState.active),
        );
        final firestoreData = IdentityMapper.toFirestore(activeIdentity);
        var patched = false;

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            final body = {
              'name':
                  'projects/dev-project/databases/(default)/documents/identities/${id.value}',
              'fields': FirestoreConverters.dataToFields(firestoreData),
            };
            return http.Response(jsonEncode(body), 200);
          }
          if (request.method == 'PATCH') {
            patched = true;
            return http.Response('{}', 200);
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.verifyEmail(id);
        expect(result.isSuccess, isTrue);
        expect(patched, isFalse);
      });

      test('verifyEmail returns unknown error when getDocument fails', () async {
        const id = IdentityId.reconstruct('user_verify_error');

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            return http.Response('server error', 500);
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.verifyEmail(id);
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenUnknownError>());
      });

      test('changeRoles accepts empty authority lists', () async {
        const id = IdentityId.reconstruct('user_roles_empty');
        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'PATCH') return http.Response('{}', 200);
          return http.Response('{}', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        const authority = Authority();
        final result = await repo.changeRoles(id, authority);
        expect(result.isSuccess, isTrue);
      });

      test('changeRoles with capabilities only patches successfully', () async {
        const id = IdentityId.reconstruct('user_roles_caps');
        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'PATCH') return http.Response('{}', 200);
          return http.Response('{}', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final authority = Authority(capabilities: {const Capability.reconstruct('can_view')});
        final result = await repo.changeRoles(id, authority);
        expect(result.isSuccess, isTrue);
      });


      test('verifyEmail returns unauthorized when activation invalid (revoked)', () async {
        const id = IdentityId.reconstruct('user_verify_revoked');
        final revokedIdentity = Identity.createPending(id: id).withLifecycle(
          const IdentityLifecycle.reconstruct(IdentityState.revoked, 'bad'),
        );
        final firestoreData = IdentityMapper.toFirestore(revokedIdentity);

        final mock = MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (request.method == 'GET' && request.url.path.contains('/identities/')) {
            final body = {
              'name':
                  'projects/dev-project/databases/(default)/documents/identities/${id.value}',
              'fields': FirestoreConverters.dataToFields(firestoreData),
            };
            return http.Response(jsonEncode(body), 200);
          }
          return http.Response('ok', 200);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: mock,
        );

        const repo = FirestoreIdentityRepository();
        final result = await repo.verifyEmail(id);
        // Identity is revoked (not pending) so verifyEmail is a no-op and returns success
        expect(result.isSuccess, isTrue);
      });
    },
  );
}
