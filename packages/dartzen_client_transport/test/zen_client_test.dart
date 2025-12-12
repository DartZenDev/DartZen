import 'package:dartzen_client_transport/dartzen_client_transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ZenClient', () {
    test('sends GET request with correct headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/test'));
        expect(request.headers[zenTransportHeaderName], equals('json'));
        expect(request.headers['Content-Type'], equals('application/json'));
        return http.Response('{"result": "ok"}', 200);
      });

      final client = ZenClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final response = await client.get('/api/test') as Map<String, dynamic>;
      expect(response, isA<Map<String, dynamic>>());
      expect(response['result'], equals('ok'));
    });

    test('sends POST request with encoded data', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/users'));
        expect(request.headers[zenTransportHeaderName], equals('json'));
        expect(request.body, isNotEmpty);
        return http.Response('{"id": 1}', 201);
      });

      final client = ZenClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final response =
          await client.post('/api/users', {'name': 'Alice'})
              as Map<String, dynamic>;
      expect(response['id'], equals(1));
    });

    test('uses msgpack format when specified', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers[zenTransportHeaderName], equals('msgpack'));
        expect(request.headers['Content-Type'], equals('application/msgpack'));
        return http.Response('', 200);
      });

      final client = ZenClient(
        baseUrl: 'http://localhost',
        format: ZenTransportFormat.msgpack,
        httpClient: mockClient,
      );

      await client.post('/api/test', {'data': 'value'});
    });

    test('includes custom headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer token'));
        return http.Response('{}', 200);
      });

      final client = ZenClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      await client.get('/api/test', headers: {'Authorization': 'Bearer token'});
    });

    test('handles empty response', () async {
      final mockClient = MockClient((request) async => http.Response('', 204));

      final client = ZenClient(
        baseUrl: 'http://localhost',
        httpClient: mockClient,
      );

      final response = await client.delete('/api/test');
      expect(response, isNull);
    });
  });
}
