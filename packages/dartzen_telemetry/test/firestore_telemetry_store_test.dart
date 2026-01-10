import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
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
  tearDown(FirestoreConnection.reset);

  test('addEvent commits batch when initialized', () async {
    Map<String, dynamic>? commitBody;

    final client = _TestHttpClient((http.Request req) async {
      // Emulator health check (GET to /documents)
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }

      // Commit endpoint
      if (req.method == 'POST' && req.url.path.contains(':commit')) {
        commitBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{}', 200);
      }

      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final event = TelemetryEvent(
      id: 'evt1',
      name: 'test.event',
      timestamp: DateTime.parse('2025-01-01T00:00:00Z'),
      scope: 'test',
      source: TelemetrySource.client,
    );

    await store.addEvent(event);

    expect(commitBody, isNotNull, reason: 'Commit body should be sent');
    final writes = commitBody!['writes'] as List<dynamic>;
    expect(writes, isNotEmpty);
    final update =
        writes.firstWhere(
              (w) => (w as Map<String, dynamic>).containsKey('update'),
            )
            as Map<String, dynamic>;
    final name = (update['update'] as Map<String, dynamic>)['name'] as String;
    expect(name, contains('/telemetry_events/'));
  });

  test('addEvent throws when connection not initialized', () async {
    FirestoreConnection.reset();
    final store = FirestoreTelemetryStore();
    final event = TelemetryEvent(
      name: 'test.event',
      timestamp: DateTime.now().toUtc(),
      scope: 'test',
      source: TelemetrySource.client,
    );

    expect(() => store.addEvent(event), throwsA(isA<StateError>()));
  });

  test('queryEvents parses runQuery response', () async {
    final runQueryResponse = [
      {
        'document': {
          'name':
              'projects/dev-project/databases/(default)/documents/telemetry_events/evt123',
          'fields': {
            'name': {'stringValue': 'my.event'},
            'timestamp': {'timestampValue': '2025-01-01T00:00:00Z'},
            'scope': {'stringValue': 'scope1'},
            'source': {'stringValue': 'client'},
            'userId': {'stringValue': 'user1'},
          },
        },
      },
    ];

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }

      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response(jsonEncode(runQueryResponse), 200);
      }

      return http.Response('not found', 404);
    });

    // Additional case: empty response
    final clientEmpty = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final results = await store.queryEvents(userId: 'user1');

    expect(results, hasLength(1));
    final evt = results.first;
    expect(evt.name, 'my.event');
    expect(evt.userId, 'user1');
    expect(evt.scope, 'scope1');

    // Verify empty response returns empty list
    FirestoreConnection.reset();
    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: clientEmpty,
    );
    final store2 = FirestoreTelemetryStore();
    final emptyResults = await store2.queryEvents(userId: 'none');
    expect(emptyResults, isEmpty);
  });

  test('queryEvents throws when not initialized', () async {
    FirestoreConnection.reset();
    final store = FirestoreTelemetryStore();
    expect(store.queryEvents, throwsA(isA<StateError>()));
  });

  test('queryEvents builds compositeFilter and includes limit', () async {
    Map<String, dynamic>? receivedBody;

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        receivedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final results = await store.queryEvents(userId: 'u', scope: 's', limit: 5);
    expect(results, isEmpty);
    expect(receivedBody, isNotNull);
    final structured = receivedBody!['structuredQuery'] as Map<String, dynamic>;
    expect(structured['limit'], 5);
    expect(structured.containsKey('where'), isTrue);
    final where = structured['where'] as Map<String, dynamic>;
    expect(where.containsKey('compositeFilter'), isTrue);
  });

  test('addEvent surfaces commit error', () async {
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains(':commit')) {
        return http.Response('server error', 500);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final event = TelemetryEvent(
      id: 'evt2',
      name: 'ok.event',
      timestamp: DateTime.parse('2025-01-01T00:00:00Z'),
      scope: 'test',
      source: TelemetrySource.client,
    );

    expect(() => store.addEvent(event), throwsA(isA<Object>()));
  });

  test('addEvent sends optional fields when present', () async {
    Map<String, dynamic>? commitBody;

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains(':commit')) {
        commitBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{}', 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final event = TelemetryEvent(
      id: 'evt_opt',
      name: 'opt.event',
      timestamp: DateTime.parse('2025-02-02T00:00:00Z'),
      scope: 'opt',
      source: TelemetrySource.server,
      userId: 'u1',
      sessionId: 's1',
      correlationId: 'c1',
      payload: const {'x': true},
    );

    await store.addEvent(event);
    expect(commitBody, isNotNull);
    final writes = commitBody!['writes'] as List<dynamic>;
    final update =
        writes.firstWhere(
              (w) => (w as Map<String, dynamic>).containsKey('update'),
            )
            as Map<String, dynamic>;
    final fields =
        (update['update'] as Map<String, dynamic>)['fields']
            as Map<String, dynamic>;
    // Ensure payload & userId present in encoded fields
    expect(fields.containsKey('userId'), isTrue);
    expect(fields.containsKey('payload'), isTrue);
  });

  test('addEvent generates id when none provided (VM-only)', () async {
    // Skip on web where Random.secure may behave differently.
    if (dzIsWeb) return;

    Map<String, dynamic>? commitBody;
    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains(':commit')) {
        commitBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{}', 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final event = TelemetryEvent(
      name: 'gen.id',
      timestamp: DateTime.parse('2025-03-03T00:00:00Z'),
      scope: 's',
      source: TelemetrySource.client,
    );

    await store.addEvent(event);
    expect(commitBody, isNotNull);
    final writes = commitBody!['writes'] as List<dynamic>;
    final update =
        writes.firstWhere(
              (w) => (w as Map<String, dynamic>).containsKey('update'),
            )
            as Map<String, dynamic>;
    final name = (update['update'] as Map<String, dynamic>)['name'] as String;
    expect(name, contains('/telemetry_events/'));
  });

  test('queryEvents builds timestamp filters for from/to', () async {
    Map<String, dynamic>? receivedBody;

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        receivedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final from = DateTime.utc(2024);
    final to = DateTime.utc(2024, 12, 31);
    await store.queryEvents(from: from, to: to);

    expect(receivedBody, isNotNull);
    final structured = receivedBody!['structuredQuery'] as Map<String, dynamic>;
    final where = structured['where'] as Map<String, dynamic>;
    // Expect compositeFilter with two range filters
    expect(
      where.containsKey('compositeFilter') || where.containsKey('fieldFilter'),
      isTrue,
    );
  });

  test(
    'queryEvents handles document without name and uses type fallback',
    () async {
      final runQueryResponse = [
        {
          'document': {
            'name': '',
            'fields': {
              'type': {'stringValue': 'fallback.type'},
              'timestamp': {'stringValue': '2025-01-02T00:00:00Z'},
              'scope': {'stringValue': 'scopeX'},
              'source': {'stringValue': 'client'},
            },
          },
        },
      ];

      final client = _TestHttpClient((http.Request req) async {
        if (req.method == 'GET' && req.url.path.contains('/documents')) {
          return http.Response('{}', 200);
        }
        if (req.method == 'POST' && req.url.path.contains('runQuery')) {
          return http.Response(jsonEncode(runQueryResponse), 200);
        }
        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final store = FirestoreTelemetryStore();
      final results = await store.queryEvents();
      expect(results, hasLength(1));
      final evt = results.first;
      expect(evt.name, 'fallback.type');
      expect(evt.scope, 'scopeX');
    },
  );

  test('queryEvents parses payload mapValue and arrayValue', () async {
    final runQueryResponse = [
      {
        'document': {
          'name':
              'projects/dev-project/databases/(default)/documents/telemetry_events/evt_map',
          'fields': {
            'name': {'stringValue': 'with.payload.map'},
            'timestamp': {'timestampValue': '2025-01-01T00:00:00Z'},
            'scope': {'stringValue': 'scopeMap'},
            'source': {'stringValue': 'server'},
            'payload': {
              'mapValue': {
                'fields': {
                  'a': {'stringValue': '1'},
                  'b': {'integerValue': '2'},
                },
              },
            },
          },
        },
      },
      {
        'document': {
          'name':
              'projects/dev-project/databases/(default)/documents/telemetry_events/evt_arr',
          'fields': {
            'name': {'stringValue': 'with.payload.array'},
            'timestamp': {'timestampValue': '2025-01-02T00:00:00Z'},
            'scope': {'stringValue': 'scopeArr'},
            'source': {'stringValue': 'client'},
            'payload': {
              'mapValue': {
                'fields': {
                  'list': {
                    'arrayValue': {
                      'values': [
                        {'stringValue': 'x'},
                        {'integerValue': '3'},
                      ],
                    },
                  },
                },
              },
            },
          },
        },
      },
    ];

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response(jsonEncode(runQueryResponse), 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final results = await store.queryEvents();
    expect(results, hasLength(2));
    final m = results.firstWhere((e) => e.name == 'with.payload.map');
    expect(m.payload, isA<Map<String, dynamic>>());
    expect(m.payload!['a'], '1');
    expect(m.payload!['b'], 2);

    final a = results.firstWhere((e) => e.name == 'with.payload.array');
    expect(a.payload, isA<Map<String, dynamic>>());
    expect(a.payload!['list'], isA<List<dynamic>>());
    expect(a.payload!['list'], contains('x'));
    expect(a.payload!['list'], contains(3));
  });

  test('queryEvents skips entries without document key', () async {
    final runQueryResponse = [
      {
        'no_document_here': {'foo': 'bar'},
      },
    ];

    final client = _TestHttpClient((http.Request req) async {
      if (req.method == 'GET' && req.url.path.contains('/documents')) {
        return http.Response('{}', 200);
      }
      if (req.method == 'POST' && req.url.path.contains('runQuery')) {
        return http.Response(jsonEncode(runQueryResponse), 200);
      }
      return http.Response('not found', 404);
    });

    await FirestoreConnection.initialize(
      const FirestoreConfig.emulator(),
      httpClient: client,
    );

    final store = FirestoreTelemetryStore();
    final results = await store.queryEvents();
    expect(results, isEmpty);
  });
}
