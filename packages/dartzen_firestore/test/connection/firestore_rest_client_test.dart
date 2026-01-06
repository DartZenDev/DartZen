import 'dart:convert';

import 'package:dartzen_firestore/src/connection/firestore_config.dart';
import 'package:dartzen_firestore/src/connection/firestore_rest_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreRestClient', () {
    test('getDocument returns mapped document on 200', () async {
      final body = jsonEncode({
        'name': 'projects/dev-project/databases/(default)/documents/col/doc1',
        'fields': {
          'a': {'stringValue': 'x'},
          'b': {'integerValue': '2'},
        },
        'createTime': '2020-01-01T00:00:00Z',
        'updateTime': '2020-01-02T00:00:00Z',
      });

      final client = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient(
          (request) async => http.Response(
            body,
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final doc = await client.getDocument('col/doc1');

      expect(doc.id, 'doc1');
      expect(doc.path, 'col/doc1');
      expect(doc.data, isNotNull);
      expect(doc.data!['a'], 'x');
      expect(doc.data!['b'], 2);
      expect(doc.createTime, isNotNull);
      expect(doc.updateTime, isNotNull);
    });

    test('getDocument returns empty document on 404', () async {
      final client = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient(
          (request) async => http.Response('Not found', 404),
        ),
      );

      final doc = await client.getDocument('col/missing');

      expect(doc.id, 'missing');
      expect(doc.path, 'col/missing');
      expect(doc.exists, isFalse);
    });

    test('getDocument throws on other status codes', () async {
      final client = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async => http.Response('error', 500)),
      );

      expect(
        () async => await client.getDocument('col/x'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('patchDocument succeeds on 200 and throws otherwise', () async {
      var called = false;
      final client = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async {
          if (request.method == 'PATCH') {
            called = true;
            return http.Response('{}', 200);
          }
          return http.Response('not found', 404);
        }),
      );

      await client.patchDocument('col/doc1', <String, dynamic>{'x': 1});
      expect(called, isTrue);

      final clientFail = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async => http.Response('bad', 500)),
      );

      expect(
        () async => await clientFail.patchDocument(
          'col/doc1',
          <String, dynamic>{'x': 1},
        ),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('beginTransaction returns transaction id on 200', () async {
      final client = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith(':beginTransaction')) {
            return http.Response(jsonEncode({'transaction': 'tx123'}), 200);
          }
          return http.Response('bad', 500);
        }),
      );

      final tx = await client.beginTransaction();
      expect(tx, 'tx123');

      final clientFail = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async => http.Response('bad', 500)),
      );

      expect(clientFail.beginTransaction, throwsA(isA<http.ClientException>()));
    });

    test('commit posts writes and throws on non-200', () async {
      var posted = false;
      final client = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith(':commit')) {
            posted = true;
            return http.Response('{}', 200);
          }
          return http.Response('bad', 500);
        }),
      );

      await client.commit(<Map<String, dynamic>>[
        <String, dynamic>{'update': <String, dynamic>{}},
      ]);
      expect(posted, isTrue);

      final clientFail = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: MockClient((request) async => http.Response('bad', 500)),
      );

      expect(
        () async => await clientFail.commit(<Map<String, dynamic>>[
          <String, dynamic>{'update': <String, dynamic>{}},
        ]),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('FirestoreRestClient error and mapping branches', () {
    test('getDocument throws on non-200 (500)', () async {
      final client = MockClient(
        (http.Request req) async => http.Response('err', 500),
      );
      final rest = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: client,
      );

      expect(
        () async => await rest.getDocument('col/doc'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('getDocument returns placeholder on 404 (error mapping)', () async {
      final client = MockClient(
        (http.Request req) async => http.Response('not found', 404),
      );
      final rest = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final doc = await rest.getDocument('col/mydoc');
      expect(doc.id, equals('mydoc'));
      expect(doc.path, equals('col/mydoc'));
    });

    test('getDocument maps when name missing (empty id/path)', () async {
      final client = MockClient(
        (http.Request req) async => http.Response(
          jsonEncode({
            'fields': {
              'a': {'stringValue': 'x'},
            },
          }),
          200,
        ),
      );

      final rest = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final doc = await rest.getDocument('col/whatever');
      expect(doc.id, isEmpty);
      expect(doc.path, isEmpty);
      expect(doc.data?['a'], equals('x'));
    });

    test('patchDocument throws on non-200', () async {
      final client = MockClient(
        (http.Request req) async => http.Response('err', 500),
      );
      final rest = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: client,
      );

      expect(
        () async => await rest.patchDocument('col/doc', {'x': 1}),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('beginTransaction throws on non-200', () async {
      final client = MockClient((http.Request req) async {
        if (req.url.path.endsWith(':beginTransaction')) {
          return http.Response('err', 500);
        }
        return http.Response('{}', 200);
      });

      final rest = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: client,
      );

      expect(
        () async => await rest.beginTransaction(),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('commit throws on non-200', () async {
      final client = MockClient((http.Request req) async {
        if (req.url.path.endsWith(':commit')) {
          return http.Response('err', 500);
        }
        return http.Response('{}', 200);
      });

      final rest = FirestoreRestClient(
        config: const FirestoreConfig.emulator(),
        httpClient: client,
      );

      expect(
        () async => await rest.commit(<Map<String, dynamic>>[
          <String, dynamic>{'update': <String, dynamic>{}},
        ]),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
