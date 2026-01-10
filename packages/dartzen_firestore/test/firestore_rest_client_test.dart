import 'dart:convert';

import 'package:dartzen_firestore/src/connection/firestore_config.dart';
import 'package:dartzen_firestore/src/connection/firestore_rest_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class _TestHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request) _handler;
  _TestHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = http.Request(request.method, request.url);
    req.headers.addAll(request.headers);
    if (request is http.Request) req.body = request.body;

    final resp = await _handler(req);

    return http.StreamedResponse(
      Stream.value(utf8.encode(resp.body)),
      resp.statusCode,
      headers: resp.headers,
      reasonPhrase: resp.reasonPhrase,
    );
  }
}

void main() {
  test('getDocument returns mapped document on 200', () async {
    final jsonResp = {
      'name': 'projects/dev-project/databases/(default)/documents/coll/doc1',
      'fields': {
        'foo': {'stringValue': 'bar'},
      },
      'createTime': '2025-01-01T00:00:00Z',
      'updateTime': '2025-01-02T00:00:00Z',
    };

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET') {
        return http.Response(jsonEncode(jsonResp), 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final doc = await rest.getDocument('coll/doc1');
    expect(doc.id, 'doc1');
    expect(doc.exists, isTrue);
    expect(doc.data, isNotNull);
    expect(doc.data!['foo'], 'bar');
    expect(doc.createTime, isNotNull);
    expect(doc.updateTime, isNotNull);
  });

  test('getDocument returns empty doc for 404', () async {
    final client = _TestHttpClient(
      (http.Request req) async => http.Response('not found', 404),
    );

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final doc = await rest.getDocument('coll/missing');
    expect(doc.id, 'missing');
    expect(doc.exists, isFalse);
  });

  test('patchDocument succeeds on 200 and throws on error', () async {
    // success
    var sawPatch = false;
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'PATCH') {
        sawPatch = true;
        return http.Response('{}', 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    await rest.patchDocument('coll/doc1', {'a': 1});
    expect(sawPatch, isTrue);

    // error
    final clientErr = _TestHttpClient(
      (http.Request req) async => http.Response('err', 500),
    );

    final restErr = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: clientErr,
    );

    expect(
      () => restErr.patchDocument('coll/doc1', {'a': 1}),
      throwsA(isA<Object>()),
    );
  });

  test('beginTransaction returns id or throws', () async {
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'POST' && req.url.path.contains('beginTransaction')) {
        return http.Response(jsonEncode({'transaction': 'tx-1'}), 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final tx = await rest.beginTransaction();
    expect(tx, 'tx-1');

    final clientErr = _TestHttpClient(
      (http.Request req) async => http.Response('err', 500),
    );

    final restErr = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: clientErr,
    );

    expect(restErr.beginTransaction, throwsA(isA<Object>()));
  });

  test('commit succeeds on 200 and throws on non-200', () async {
    var sawCommit = false;

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'POST' && req.url.path.contains(':commit')) {
        sawCommit = true;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body.containsKey('writes'), isTrue);
        return http.Response('{}', 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    await rest.commit([
      {
        'update': {
          'name':
              'projects/dev-project/databases/(default)/documents/coll/doc1',
          'fields': {
            'f': {'stringValue': 'v'},
          },
        },
      },
    ]);
    expect(sawCommit, isTrue);

    final clientErr = _TestHttpClient(
      (http.Request req) async => http.Response('err', 500),
    );

    final restErr = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: clientErr,
    );

    expect(() => restErr.commit([]), throwsA(isA<Object>()));
  });

  test('runStructuredQuery returns list on 200 and throws on error', () async {
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final List<dynamic> res = await rest.runStructuredQuery(<String, dynamic>{
      'from': <Map<String, dynamic>>[],
    });
    expect(res, isA<List<dynamic>>());

    final clientErr = _TestHttpClient(
      (http.Request req) async => http.Response('err', 500),
    );

    final restErr = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: clientErr,
    );

    expect(
      () => restErr.runStructuredQuery(<String, dynamic>{
        'from': <Map<String, dynamic>>[],
      }),
      throwsA(isA<Object>()),
    );
  });

  test('runStructuredQuery throws when response is not a list', () async {
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response(jsonEncode({'not': 'a list'}), 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    expect(
      () => rest.runStructuredQuery(<String, dynamic>{
        'from': <Map<String, dynamic>>[],
      }),
      throwsA(isA<Object>()),
    );
  });

  test('runStructuredQuery throws on invalid JSON body', () async {
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response('not-json', 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.emulator(),
      httpClient: client,
    );

    expect(
      () => rest.runStructuredQuery(<String, dynamic>{
        'from': <Map<String, dynamic>>[],
      }),
      throwsA(isA<Object>()),
    );
  });

  test('runStructuredQuery uses production base URL when configured', () async {
    String? seenUrl;
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        seenUrl = req.url.toString();
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not found', 404);
    });

    final rest = FirestoreRestClient(
      config: const FirestoreConfig.production(projectId: 'prod-project'),
      httpClient: client,
    );

    await rest.runStructuredQuery(<String, dynamic>{
      'from': <Map<String, dynamic>>[],
    });
    expect(seenUrl, isNotNull);
    expect(seenUrl!, contains('firestore.googleapis.com'));
    expect(seenUrl!, contains(':runQuery'));
  });
}
