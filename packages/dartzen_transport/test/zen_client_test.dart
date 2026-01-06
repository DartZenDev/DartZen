import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ZenClient', () {
    const baseUrl = 'http://localhost:8080';

    group('GET requests', () {
      test('returns ZenResponse with decoded JSON body on success', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), '$baseUrl/api/users');
          expect(request.headers[zenTransportHeaderName], 'json');
          expect(request.headers['Content-Type'], 'application/json');

          return http.Response(
            jsonEncode({'id': '123', 'name': 'Alice'}),
            200,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/users');

        expect(response.status, 200);
        expect(response.isSuccess, true);
        expect(response.isError, false);
        expect(response.data, {'id': '123', 'name': 'Alice'});
        expect(response.error, isNull);

        client.close();
      });

      test('returns ZenResponse with error on 404', () async {
        final mockClient = MockClient(
          (request) async => http.Response(
            jsonEncode({'error': 'Not found'}),
            404,
            headers: {zenTransportHeaderName: 'json'},
          ),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/users/999');

        expect(response.status, 404);
        expect(response.isSuccess, false);
        expect(response.isError, true);
        expect(response.error, 'Not found');
        expect(response.data, {'error': 'Not found'});

        client.close();
      });

      test('returns ZenResponse with error on 500', () async {
        final mockClient = MockClient(
          (request) async => http.Response(
            jsonEncode({'message': 'Internal server error'}),
            500,
            headers: {zenTransportHeaderName: 'json'},
          ),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/users');

        expect(response.status, 500);
        expect(response.isSuccess, false);
        expect(response.isError, true);
        expect(response.error, 'Internal server error');

        client.close();
      });

      test('handles empty response body', () async {
        final mockClient = MockClient(
          (request) async => http.Response('', 204),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/users');

        expect(response.status, 204);
        expect(response.isSuccess, true);
        expect(response.data, isNull);
        expect(response.error, isNull);

        client.close();
      });

      test('uses reasonPhrase when no error message in body', () async {
        final mockClient = MockClient(
          (request) async => http.Response('', 403, reasonPhrase: 'Forbidden'),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/admin');

        expect(response.status, 403);
        expect(response.error, 'Forbidden');

        client.close();
      });

      test('includes custom headers', () async {
        final mockClient = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token123');
          return http.Response(jsonEncode({}), 200);
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        await client.get(
          '/api/users',
          headers: {'Authorization': 'Bearer token123'},
        );

        client.close();
      });
    });

    group('POST requests', () {
      test('encodes request body and returns ZenResponse', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), '$baseUrl/api/users');
          expect(request.headers[zenTransportHeaderName], 'json');

          final decoded = jsonDecode(utf8.decode(request.bodyBytes));
          expect(decoded, {'name': 'Bob', 'email': 'bob@example.com'});

          return http.Response(
            jsonEncode({'id': '456', 'name': 'Bob'}),
            201,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.post('/api/users', {
          'name': 'Bob',
          'email': 'bob@example.com',
        });

        expect(response.status, 201);
        expect(response.isSuccess, true);
        expect(response.data, {'id': '456', 'name': 'Bob'});

        client.close();
      });

      test('handles validation error response', () async {
        final mockClient = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'error': 'Validation failed',
              'details': {'email': 'Invalid email format'},
            }),
            400,
            headers: {zenTransportHeaderName: 'json'},
          ),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.post('/api/users', {'email': 'invalid'});

        expect(response.status, 400);
        expect(response.isError, true);
        expect(response.error, 'Validation failed');

        client.close();
      });
    });

    group('PUT requests', () {
      test('updates resource and returns ZenResponse', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.toString(), '$baseUrl/api/users/123');

          return http.Response(
            jsonEncode({'id': '123', 'name': 'Updated'}),
            200,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.put('/api/users/123', {
          'name': 'Updated',
        });

        expect(response.status, 200);
        expect(response.isSuccess, true);

        client.close();
      });
    });

    group('DELETE requests', () {
      test('deletes resource and returns ZenResponse', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.toString(), '$baseUrl/api/users/123');

          return http.Response('', 204);
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.delete('/api/users/123');

        expect(response.status, 204);
        expect(response.isSuccess, true);

        client.close();
      });
    });

    group('MessagePack format', () {
      test('uses msgpack content-type and encoding', () async {
        final mockClient = MockClient((request) async {
          expect(request.headers['Content-Type'], 'application/msgpack');
          expect(request.headers[zenTransportHeaderName], 'msgpack');

          // Return msgpack-encoded response
          final responseData = {'result': 'success'};
          final encoded = ZenEncoder.encode(
            responseData,
            ZenTransportFormat.msgpack,
          );

          return http.Response.bytes(
            encoded,
            200,
            headers: {zenTransportHeaderName: 'msgpack'},
          );
        });

        final client = ZenClient(
          baseUrl: baseUrl,
          format: ZenTransportFormat.msgpack,
          httpClient: mockClient,
        );

        final response = await client.post('/api/data', {'test': 'value'});

        expect(response.status, 200);
        expect(response.data, {'result': 'success'});

        client.close();
      });

      test('handles format mismatch gracefully', () async {
        final mockClient = MockClient(
          (request) async =>
              // Server responds with different format than requested
              http.Response(
                jsonEncode({'data': 'json'}),
                200,
                headers: {zenTransportHeaderName: 'json'},
              ),
        );

        final client = ZenClient(
          baseUrl: baseUrl,
          format: ZenTransportFormat.msgpack,
          httpClient: mockClient,
        );

        final response = await client.get('/api/data');

        expect(response.status, 200);
        expect(response.data, {'data': 'json'});

        client.close();
      });
    });

    group('error handling', () {
      test('handles malformed response body gracefully', () async {
        final mockClient = MockClient(
          (request) async => http.Response(
            'not json at all',
            200,
            headers: {zenTransportHeaderName: 'json'},
          ),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/broken');

        expect(response.status, 200);
        expect(response.data, isNull);

        client.close();
      });

      test(
        'distinguishes between error responses with same data structure',
        () async {
          final successClient = ZenClient(
            baseUrl: baseUrl,
            httpClient: MockClient(
              (request) async =>
                  http.Response(jsonEncode({'error': 'False alarm'}), 200),
            ),
          );

          final errorClient = ZenClient(
            baseUrl: baseUrl,
            httpClient: MockClient(
              (request) async =>
                  http.Response(jsonEncode({'error': 'Real error'}), 500),
            ),
          );

          final successResponse = await successClient.get('/api/test');
          final errorResponse = await errorClient.get('/api/test');

          expect(successResponse.isSuccess, true);
          expect(successResponse.isError, false);
          expect(successResponse.error, isNull);

          expect(errorResponse.isSuccess, false);
          expect(errorResponse.isError, true);
          expect(errorResponse.error, 'Real error');

          successClient.close();
          errorClient.close();
        },
      );
    });

    group('request ID tracking', () {
      test('generates unique request IDs', () async {
        final requestIds = <String>[];

        final mockClient = MockClient((request) async {
          final requestId = request.headers[requestIdHeaderName];
          expect(requestId, isNotNull);
          requestIds.add(requestId!);

          return http.Response(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        // Make multiple requests
        await client.get('/api/test1');
        await client.get('/api/test2');
        await client.post('/api/test3', {'data': 'test'});

        // Verify all IDs are unique
        expect(requestIds.length, 3);
        expect(requestIds.toSet().length, 3); // All unique

        // Verify ID format (req-{timestamp}-{counter})
        for (final id in requestIds) {
          expect(id, startsWith('req-'));
          expect(id.split('-').length, 3);
        }

        client.close();
      });

      test('includes request ID in X-Request-ID header', () async {
        final mockClient = MockClient((request) async {
          final requestId = request.headers[requestIdHeaderName];
          expect(requestId, isNotNull);
          expect(requestId, matches(r'^req-\d+-\d+$'));

          return http.Response(
            jsonEncode({'result': 'success'}),
            200,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        await client.get('/api/test');

        client.close();
      });

      test('returns request ID in ZenResponse', () async {
        String? capturedRequestId;

        final mockClient = MockClient((request) async {
          capturedRequestId = request.headers[requestIdHeaderName];

          return http.Response(
            jsonEncode({'data': 'test'}),
            200,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/test');

        expect(response.id, isNotEmpty);
        expect(response.id, equals(capturedRequestId));

        client.close();
      });

      test('request ID is included in error responses', () async {
        String? capturedRequestId;

        final mockClient = MockClient((request) async {
          capturedRequestId = request.headers[requestIdHeaderName];

          return http.Response(
            jsonEncode({'error': 'Not found'}),
            404,
            headers: {zenTransportHeaderName: 'json'},
          );
        });

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response = await client.get('/api/missing');

        expect(response.id, isNotEmpty);
        expect(response.id, equals(capturedRequestId));
        expect(response.isError, true);

        client.close();
      });

      test('request ID counter increments correctly', () async {
        final mockClient = MockClient(
          (request) async => http.Response(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {zenTransportHeaderName: 'json'},
          ),
        );

        final client = ZenClient(baseUrl: baseUrl, httpClient: mockClient);

        final response1 = await client.get('/api/test');
        final response2 = await client.get('/api/test');
        final response3 = await client.get('/api/test');

        // Extract counter from IDs (format: req-timestamp-counter)
        final counter1 = int.parse(response1.id.split('-').last);
        final counter2 = int.parse(response2.id.split('-').last);
        final counter3 = int.parse(response3.id.split('-').last);

        expect(counter1, 1);
        expect(counter2, 2);
        expect(counter3, 3);

        client.close();
      });

      group('ZenClient edge cases', () {
        test('handles unknown transport header gracefully', () async {
          final mock = MockClient(
            (request) async => http.Response.bytes(
              utf8.encode(jsonEncode({'data': 'x'})),
              200,
              headers: {zenTransportHeaderName: 'unknown-format'},
            ),
          );

          final client = ZenClient(baseUrl: baseUrl, httpClient: mock);

          // Should not throw; decoded data becomes null due to parse/decode failure
          final resp = await client.get('/api/x');
          expect(resp.status, 200);
          expect(resp.data, isNull);

          client.close();
        });

        test('msgpack decoding failure yields null data (no throw)', () async {
          final invalidMsgpack = Uint8List.fromList([0xC1]); // reserved/invalid

          final mock = MockClient(
            (request) async => http.Response.bytes(
              invalidMsgpack,
              200,
              headers: {zenTransportHeaderName: 'msgpack'},
            ),
          );

          final client = ZenClient(
            baseUrl: baseUrl,
            format: ZenTransportFormat.msgpack,
            httpClient: mock,
          );

          final resp = await client.get('/api/msg');
          // Decoder should fail internally and client should return null data
          expect(resp.status, 200);
          expect(resp.data, isNull);

          client.close();
        });

        test(
          'custom headers override default Content-Type and format header',
          () async {
            final mock = MockClient((request) async {
              // Custom headers passed by caller should win
              expect(
                request.headers['Content-Type'],
                equals('application/custom'),
              );
              expect(
                request.headers[zenTransportHeaderName],
                equals('customfmt'),
              );

              return http.Response(
                jsonEncode({'ok': true}),
                200,
                headers: {zenTransportHeaderName: 'json'},
              );
            });

            final client = ZenClient(baseUrl: baseUrl, httpClient: mock);

            await client.get(
              '/api/custom',
              headers: {
                'Content-Type': 'application/custom',
                zenTransportHeaderName: 'customfmt',
              },
            );

            client.close();
          },
        );
      });
    });
  });

  group('ZenTransport basic behaviors', () {
    test('ZenTransportFormat.parse accepts valid and rejects invalid', () {
      expect(ZenTransportFormat.parse('json'), equals(ZenTransportFormat.json));
      expect(
        ZenTransportFormat.parse('msgpack'),
        equals(ZenTransportFormat.msgpack),
      );
      expect(
        () => ZenTransportFormat.parse('invalid'),
        throwsA(isA<ZenTransportException>()),
      );
    });

    test('ZenRequest/ZenResponse toMap/fromMap and equality/hashCode', () {
      const req = ZenRequest(id: '1', path: '/x', data: {'k': 'v'});
      final rmap = req.toMap();
      final req2 = ZenRequest.fromMap(rmap);
      expect(req2, equals(req));
      expect(req.hashCode, equals(req2.hashCode));

      const resp = ZenResponse(id: '1', status: 200, data: {'ok': true});
      final rmap2 = resp.toMap();
      final resp2 = ZenResponse.fromMap(rmap2);
      expect(resp2, equals(resp));
      expect(resp.isSuccess, isTrue);
      expect(resp.isError, isFalse);
    });

    test('ZenMessage encode/decodeWith roundtrip (json and msgpack)', () {
      const req = ZenRequest(id: '42', path: '/test', data: {'n': 1});

      final jsonBytes = req.encodeWith(ZenTransportFormat.json);
      final decodedJson = ZenMessage.decodeWith(
        Uint8List.fromList(jsonBytes),
        ZenTransportFormat.json,
      );
      expect(decodedJson['id'], equals('42'));

      final mpBytes = req.encodeWith(ZenTransportFormat.msgpack);
      final decodedMp = ZenMessage.decodeWith(
        Uint8List.fromList(mpBytes),
        ZenTransportFormat.msgpack,
      );
      expect(decodedMp['id'], equals('42'));
    });

    test('ZenClient decodes response and extracts error/message', () async {
      final bodyMap = {'id': 'r1', 'status': 400, 'error': 'bad'};
      final bodyBytes = ZenEncoder.encode(bodyMap, ZenTransportFormat.json);

      final mock = MockClient(
        (http.Request request) async => http.Response.bytes(
          bodyBytes,
          400,
          headers: {zenTransportHeaderName: 'json'},
        ),
      );

      final client = ZenClient(baseUrl: 'http://localhost', httpClient: mock);
      final resp = await client.get('/x');
      expect(resp.status, equals(400));
      expect(resp.error, contains('bad'));
    });
  });
}
