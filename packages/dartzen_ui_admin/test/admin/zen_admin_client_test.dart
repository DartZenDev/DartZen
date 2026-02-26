import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_client.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransport extends Mock implements ZenTransport {}

void main() {
  late _MockTransport transport;
  late ZenAdminClient client;

  setUpAll(() {
    registerFallbackValue(
      const TransportDescriptor(
        id: 'fallback',
        channel: TransportChannel.http,
        reliability: TransportReliability.atMostOnce,
      ),
    );
  });

  setUp(() {
    transport = _MockTransport();
    client = ZenAdminClient(transport: transport);
  });

  /// Stubs [transport.send] to return [result] for any call.
  void stubSend(TransportResult result) {
    when(
      () => transport.send(
        any(),
        payload: any(named: 'payload'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => result);
  }

  /// Captures the [TransportDescriptor] and payload from the last call.
  (TransportDescriptor, Map<String, dynamic>) capturedSend() {
    final captured = verify(
      () => transport.send(
        captureAny(),
        payload: captureAny(named: 'payload'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).captured;
    return (
      captured[0] as TransportDescriptor,
      captured[1] as Map<String, dynamic>,
    );
  }

  group('ZenAdminClient.query', () {
    test('sends correct descriptor and payload', () async {
      stubSend(
        TransportResult.ok(
          data: <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'id': '1', 'name': 'Alice'},
            ],
            'total': 1,
            'offset': 0,
            'limit': 20,
          },
        ),
      );

      final page = await client.query(
        'users',
        const ZenAdminQuery(offset: 0, limit: 20),
      );

      final (descriptor, payload) = capturedSend();
      expect(descriptor.id, 'admin.query');
      expect(payload['resource'], 'users');
      expect(payload['path'], '/v1/admin/users/query');
      expect(payload['offset'], 0);
      expect(payload['limit'], 20);
      expect(page.items.length, 1);
      expect(page.total, 1);
      expect(page.items.first['name'], 'Alice');
    });

    test('throws on failure', () async {
      stubSend(TransportResult.err(error: 'Bad request'));

      expect(
        () => client.query('users', const ZenAdminQuery()),
        throwsA(
          isA<ZenTransportException>().having(
            (e) => e.message,
            'message',
            'Bad request',
          ),
        ),
      );
    });

    test('throws with default message when error is null', () async {
      stubSend(TransportResult.err());

      expect(
        () => client.query('users', const ZenAdminQuery()),
        throwsA(
          isA<ZenTransportException>().having(
            (e) => e.message,
            'message',
            'Query failed',
          ),
        ),
      );
    });
  });

  group('ZenAdminClient.fetchById', () {
    test('sends correct descriptor and payload', () async {
      stubSend(
        TransportResult.ok(data: <String, dynamic>{'id': '42', 'name': 'Bob'}),
      );

      final data = await client.fetchById('users', '42');

      final (descriptor, payload) = capturedSend();
      expect(descriptor.id, 'admin.fetch');
      expect(payload['resource'], 'users');
      expect(payload['path'], '/v1/admin/users/42');
      expect(payload['id'], '42');
      expect(data['name'], 'Bob');
    });

    test('throws on failure', () async {
      stubSend(TransportResult.err(error: 'Not found'));

      expect(
        () => client.fetchById('users', '99'),
        throwsA(isA<ZenTransportException>()),
      );
    });
  });

  group('ZenAdminClient.create', () {
    test('sends correct descriptor and payload', () async {
      stubSend(TransportResult.ok());

      await client.create('users', {'name': 'Charlie'});

      final (descriptor, payload) = capturedSend();
      expect(descriptor.id, 'admin.create');
      expect(payload['resource'], 'users');
      expect(payload['path'], '/v1/admin/users');
      expect((payload['data'] as Map)['name'], 'Charlie');
    });

    test('throws on failure', () async {
      stubSend(TransportResult.err(error: 'Conflict'));

      expect(
        () => client.create('users', {'name': 'X'}),
        throwsA(isA<ZenTransportException>()),
      );
    });
  });

  group('ZenAdminClient.update', () {
    test('sends correct descriptor and payload', () async {
      stubSend(TransportResult.ok());

      await client.update('users', '1', {'name': 'Updated'});

      final (descriptor, payload) = capturedSend();
      expect(descriptor.id, 'admin.update');
      expect(payload['resource'], 'users');
      expect(payload['path'], '/v1/admin/users/1');
      expect(payload['id'], '1');
      expect((payload['data'] as Map)['name'], 'Updated');
    });

    test('throws on failure', () async {
      stubSend(TransportResult.err(error: 'Error'));

      expect(
        () => client.update('users', '1', {}),
        throwsA(isA<ZenTransportException>()),
      );
    });
  });

  group('ZenAdminClient.delete', () {
    test('sends correct descriptor and payload', () async {
      stubSend(TransportResult.ok());

      await client.delete('users', '1');

      final (descriptor, payload) = capturedSend();
      expect(descriptor.id, 'admin.delete');
      expect(payload['resource'], 'users');
      expect(payload['path'], '/v1/admin/users/1');
      expect(payload['id'], '1');
    });

    test('throws on failure', () async {
      stubSend(TransportResult.err(error: 'Forbidden'));

      expect(
        () => client.delete('users', '1'),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('throws with default message when error is null', () async {
      stubSend(TransportResult.err());

      expect(
        () => client.delete('users', '1'),
        throwsA(
          isA<ZenTransportException>().having(
            (e) => e.message,
            'message',
            'Delete failed',
          ),
        ),
      );
    });
  });
}
