import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _BatchTelemetry implements FirestoreTelemetry {
  int? lastOperationCount;
  bool onBatchCalled = false;
  bool onErrorCalled = false;

  @override
  void onBatchCommit(
    int operationCount,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {
    onBatchCalled = true;
    lastOperationCount = operationCount;
  }

  @override
  void onError(
    String operation,
    ZenError error, {
    Map<String, dynamic>? metadata,
  }) {
    onErrorCalled = true;
  }

  @override
  void onNotFound(String path, {Map<String, dynamic>? metadata}) {}

  @override
  void onRead(
    String path,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void onTransactionComplete(
    Duration latency,
    bool success, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void onWrite(
    String path,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}
}

void main() {
  group('FirestoreBatch', () {
    tearDown(FirestoreConnection.reset);

    test('empty commit returns ok without calling telemetry', () async {
      final batch = FirestoreBatch();
      final result = await batch.commit();
      expect(result.isSuccess, isTrue);
    });

    test('set/update/delete produce writes and commit succeeds', () async {
      final commitRequests = <http.Request>[];

      final client = MockClient((http.Request req) async {
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }
        if (req.method == 'POST' && req.url.path.endsWith(':commit')) {
          commitRequests.add(req);
          return http.Response(
            jsonEncode({'commitTime': '2024-01-01T00:00:00Z'}),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final telemetry = _BatchTelemetry();
      final batch = FirestoreBatch(telemetry: telemetry);

      batch.set('col/doc1', {'a': 1});
      batch.update('col/doc2', {'b': 2});
      batch.delete('col/doc3');

      final res = await batch.commit(metadata: {'foo': 'bar'});
      expect(res.isSuccess, isTrue);
      expect(telemetry.onBatchCalled, isTrue);
      expect(telemetry.lastOperationCount, 3);
      expect(commitRequests, isNotEmpty);

      final body =
          jsonDecode(commitRequests.single.body) as Map<String, dynamic>;
      expect((body['writes'] as List).length, 3);
    });

    test('commit failure returns error and telemetry.onError called', () async {
      final client = MockClient((http.Request req) async {
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }
        if (req.method == 'POST' && req.url.path.endsWith(':commit')) {
          return http.Response('err', 500);
        }
        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final telemetry = _BatchTelemetry();
      final batch = FirestoreBatch(telemetry: telemetry);
      batch.set('col/doc', {'x': 1});

      final res = await batch.commit();
      expect(res.isFailure, isTrue);
      expect(telemetry.onErrorCalled, isTrue);
    });

    test('exceeding 500 operations throws StateError', () async {
      final client = MockClient((http.Request req) async {
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }
        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final batch = FirestoreBatch();
      for (var i = 0; i < 500; i++) {
        batch.set('col/$i', {'v': i});
      }

      expect(() => batch.set('col/overflow', {'v': 1}), throwsStateError);
    });
  });
}
