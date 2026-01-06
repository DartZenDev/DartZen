import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _TestTelemetry implements FirestoreTelemetry {
  bool onTransactionCompleteCalled = false;
  bool lastSuccess = false;
  bool onErrorCalled = false;

  @override
  void onBatchCommit(
    int operationCount,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}

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
  }) {
    onTransactionCompleteCalled = true;
    lastSuccess = success;
  }

  @override
  void onWrite(
    String path,
    Duration latency, {
    Map<String, dynamic>? metadata,
  }) {}
}

void main() {
  group('FirestoreTransaction.run', () {
    tearDown(FirestoreConnection.reset);

    test('commits on success and notifies telemetry', () async {
      final commitRequests = <http.Request>[];

      final client = MockClient((http.Request req) async {
        // health-check from initialize
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }

        // beginTransaction
        if (req.method == 'POST' &&
            req.url.path.endsWith(':beginTransaction')) {
          return http.Response(jsonEncode({'transaction': 'tx-1'}), 200);
        }

        // commit
        if (req.method == 'POST' && req.url.path.endsWith(':commit')) {
          commitRequests.add(req);
          return http.Response('{}', 200);
        }

        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final telemetry = _TestTelemetry();

      final result = await FirestoreTransaction.run<String>((
        Transaction tx,
      ) async {
        tx.set('col/doc', {'x': 'y'});
        return const ZenResult.ok('ok');
      }, telemetry: telemetry);

      expect(result.isSuccess, isTrue);
      expect(telemetry.onTransactionCompleteCalled, isTrue);
      expect(telemetry.lastSuccess, isTrue);
      expect(commitRequests, isNotEmpty);

      final body =
          jsonDecode(commitRequests.single.body) as Map<String, dynamic>;
      expect(body.containsKey('writes'), isTrue);
    });

    test('returns error when beginTransaction fails', () async {
      final client = MockClient((http.Request req) async {
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }
        if (req.method == 'POST' &&
            req.url.path.endsWith(':beginTransaction')) {
          return http.Response('err', 500);
        }
        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final telemetry = _TestTelemetry();

      final result = await FirestoreTransaction.run<String>(
        (Transaction tx) async => const ZenResult.ok('ok'),
        telemetry: telemetry,
      );

      expect(result.isFailure, isTrue);
      expect(telemetry.onTransactionCompleteCalled, isTrue);
      expect(telemetry.lastSuccess, isFalse);
      expect(telemetry.onErrorCalled, isTrue);
    });

    test('propagates operation throw into error result', () async {
      final client = MockClient((http.Request req) async {
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }
        if (req.method == 'POST' &&
            req.url.path.endsWith(':beginTransaction')) {
          return http.Response(jsonEncode({'transaction': 'tx-2'}), 200);
        }
        if (req.method == 'POST' && req.url.path.endsWith(':commit')) {
          return http.Response('{}', 200);
        }
        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final telemetry = _TestTelemetry();

      final result = await FirestoreTransaction.run<String>((
        Transaction tx,
      ) async {
        throw StateError('boom');
      }, telemetry: telemetry);

      expect(result.isFailure, isTrue);
      expect(telemetry.onTransactionCompleteCalled, isTrue);
      expect(telemetry.lastSuccess, isFalse);
      expect(telemetry.onErrorCalled, isTrue);
    });

    test('Transaction.get returns mapped document', () async {
      final client = MockClient((http.Request req) async {
        // health-check from initialize
        if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
          return http.Response('{}', 200);
        }

        // get document within transaction
        if (req.method == 'GET' &&
            req.url.path.contains('/documents/col/doc')) {
          return http.Response(
            jsonEncode({
              'name':
                  'projects/dev-project/databases/(default)/documents/col/doc',
              'fields': {
                'x': {'stringValue': 'y'},
              },
              'createTime': '2024-01-01T00:00:00Z',
              'updateTime': '2024-01-02T00:00:00Z',
            }),
            200,
          );
        }

        return http.Response('not found', 404);
      });

      await FirestoreConnection.initialize(
        const FirestoreConfig.emulator(),
        httpClient: client,
      );

      final tx = Transaction('tx-123');
      final doc = await tx.get('col/doc');

      expect(doc.id, equals('doc'));
      expect(doc.path, equals('col/doc'));
      expect(doc.data, isNotNull);
      expect(doc.data?['x'], equals('y'));
      expect(doc.createTime, isNotNull);
      expect(doc.updateTime, isNotNull);
    });

    test(
      'set/update produce correct currentDocument flags on commit',
      () async {
        final commitRequests = <http.Request>[];

        final client = MockClient((http.Request req) async {
          if (req.method == 'GET' && req.url.path.endsWith('/documents')) {
            return http.Response('{}', 200);
          }
          if (req.method == 'POST' &&
              req.url.path.endsWith(':beginTransaction')) {
            return http.Response(jsonEncode({'transaction': 'tx-flag'}), 200);
          }
          if (req.method == 'POST' && req.url.path.endsWith(':commit')) {
            commitRequests.add(req);
            return http.Response('{}', 200);
          }
          return http.Response('not found', 404);
        });

        await FirestoreConnection.initialize(
          const FirestoreConfig.emulator(),
          httpClient: client,
        );

        final telemetry = _TestTelemetry();

        final result = await FirestoreTransaction.run<String>((
          Transaction tx,
        ) async {
          tx.set('col/setdoc', {'a': 1});
          tx.update('col/updoc', {'b': 2});
          return const ZenResult.ok('done');
        }, telemetry: telemetry);

        expect(result.isSuccess, isTrue);
        expect(commitRequests, isNotEmpty);

        final body =
            jsonDecode(commitRequests.single.body) as Map<String, dynamic>;
        final writes = (body['writes'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        // There should be two writes; find update write and set write
        final updateWrite = writes.firstWhere((w) {
          final update = w['update'] as Map<String, dynamic>?;
          return update != null &&
              update['name']?.toString().contains('updoc') == true;
        });

        final setWrite = writes.firstWhere((w) {
          final update = w['update'] as Map<String, dynamic>?;
          return update != null &&
              update['name']?.toString().contains('setdoc') == true;
        });

        expect(
          (updateWrite['currentDocument'] as Map<String, dynamic>)['exists'],
          isTrue,
        );
        expect(
          (setWrite['currentDocument'] as Map<String, dynamic>)['exists'],
          isFalse,
        );
      },
    );
  });
}
