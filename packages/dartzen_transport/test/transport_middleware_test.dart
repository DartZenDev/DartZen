import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('transportMiddleware', () {
    group('request decoding', () {
      test('decodes JSON request body and stores in context', () async {
        final handler = expectAsync1<Response, Request>((request) {
          expect(request.context['transport_format'], ZenTransportFormat.json);
          expect(request.context['decoded_data'], {'name': 'Alice'});
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/users'),
          body: jsonEncode({'name': 'Alice'}),
          headers: {
            'Content-Type': 'application/json',
            zenTransportHeaderName: 'json',
          },
        );

        await pipeline(request);
      });

      test('decodes MessagePack request body', () async {
        final testData = {'name': 'Bob', 'age': 30};
        final encoded = ZenEncoder.encode(testData, ZenTransportFormat.msgpack);

        final handler = expectAsync1<Response, Request>((request) {
          expect(
            request.context['transport_format'],
            ZenTransportFormat.msgpack,
          );
          expect(request.context['decoded_data'], testData);
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/data'),
          body: encoded,
          headers: {
            'Content-Type': 'application/msgpack',
            zenTransportHeaderName: 'msgpack',
          },
        );

        await pipeline(request);
      });

      test('handles empty request body', () async {
        final handler = expectAsync1<Response, Request>((request) {
          expect(request.context['transport_format'], ZenTransportFormat.json);
          expect(request.context['decoded_data'], isNull);
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/api/users'),
          headers: {zenTransportHeaderName: 'json'},
        );

        await pipeline(request);
      });

      test('negotiates format from Content-Type header', () async {
        final handler = expectAsync1<Response, Request>((request) {
          expect(
            request.context['transport_format'],
            ZenTransportFormat.msgpack,
          );
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/api/data'),
          headers: {'Content-Type': 'application/msgpack'},
        );

        await pipeline(request);
      });

      test('defaults to JSON when no format specified', () async {
        final handler = expectAsync1<Response, Request>((request) {
          expect(request.context['transport_format'], ZenTransportFormat.json);
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request('GET', Uri.parse('http://localhost/api/users'));

        await pipeline(request);
      });

      test(
        'X-DZ-Transport header takes precedence over Content-Type',
        () async {
          final handler = expectAsync1<Response, Request>((request) {
            expect(
              request.context['transport_format'],
              ZenTransportFormat.msgpack,
            );
            return Response.ok('');
          });

          final middleware = transportMiddleware();
          final pipeline = middleware(handler);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/api/data'),
            headers: {
              'Content-Type': 'application/json',
              zenTransportHeaderName: 'msgpack',
            },
          );

          await pipeline(request);
        },
      );
    });

    group('response encoding', () {
      test('encodes response data as JSON when using zenResponse', () async {
        Response handler(Request request) =>
            zenResponse(200, {'id': '123', 'name': 'Alice'});

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/api/users/123'),
          headers: {zenTransportHeaderName: 'json'},
        );

        final response = await pipeline(request);

        expect(response.statusCode, 200);
        expect(response.headers['Content-Type'], 'application/json');
        expect(response.headers[zenTransportHeaderName], 'json');

        final body = await response.readAsString();
        final decoded = jsonDecode(body);
        expect(decoded, {'id': '123', 'name': 'Alice'});
      });

      test('encodes response data as MessagePack when requested', () async {
        Response handler(Request request) =>
            zenResponse(200, {'result': 'success'});

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/action'),
          headers: {zenTransportHeaderName: 'msgpack'},
        );

        final response = await pipeline(request);

        expect(response.statusCode, 200);
        expect(response.headers['Content-Type'], 'application/msgpack');
        expect(response.headers[zenTransportHeaderName], 'msgpack');

        final bodyBytes = await response.read().toList();
        final bytes = Uint8List.fromList(
          bodyBytes.expand((chunk) => chunk).toList(),
        );
        final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
        expect(decoded, {'result': 'success'});
      });

      test('passes through non-zen responses unchanged', () async {
        Response handler(Request request) => Response.ok('Plain text response');

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request('GET', Uri.parse('http://localhost/health'));

        final response = await pipeline(request);

        expect(response.statusCode, 200);
        expect(response.headers[zenTransportHeaderName], isNull);

        final body = await response.readAsString();
        expect(body, 'Plain text response');
      });

      test('zenResponse supports custom headers', () async {
        Response handler(Request request) => zenResponse(
          201,
          {'id': '999'},
          headers: {'X-Custom-Header': 'test-value'},
        );

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/items'),
          headers: {zenTransportHeaderName: 'json'},
        );

        final response = await pipeline(request);

        expect(response.statusCode, 201);
        expect(response.headers['X-Custom-Header'], 'test-value');
      });

      test('handles empty data in zenResponse', () async {
        Response handler(Request request) => zenResponse(204, {});

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'DELETE',
          Uri.parse('http://localhost/api/users/123'),
          headers: {zenTransportHeaderName: 'json'},
        );

        final response = await pipeline(request);

        expect(response.statusCode, 204);

        final body = await response.readAsString();
        expect(body, '{}');
      });
    });

    group('format negotiation edge cases', () {
      test('handles invalid X-DZ-Transport header gracefully', () async {
        final handler = expectAsync1<Response, Request>((request) {
          expect(request.context['transport_format'], ZenTransportFormat.json);
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/api/users'),
          headers: {zenTransportHeaderName: 'invalid-format'},
        );

        await pipeline(request);
      });

      test('handles mixed Content-Type variations', () async {
        final handler = expectAsync1<Response, Request>((request) {
          expect(request.context['transport_format'], ZenTransportFormat.json);
          return Response.ok('');
        });

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/data'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        );

        await pipeline(request);
      });
    });

    group('integration scenarios', () {
      test('full request-response cycle with JSON', () async {
        Response handler(Request request) {
          final data = request.context['decoded_data'] as Map<String, dynamic>;
          return zenResponse(200, {
            'received': data['name'],
            'processed': true,
          });
        }

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/process'),
          body: jsonEncode({'name': 'Test'}),
          headers: {
            'Content-Type': 'application/json',
            zenTransportHeaderName: 'json',
          },
        );

        final response = await pipeline(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final decoded = jsonDecode(body);
        expect(decoded, {'received': 'Test', 'processed': true});
      });

      test('full request-response cycle with MessagePack', () async {
        Response handler(Request request) {
          final data = request.context['decoded_data'] as Map<String, dynamic>;
          return zenResponse(200, {'echo': data['value']});
        }

        final middleware = transportMiddleware();
        final pipeline = middleware(handler);

        final requestData = {'value': 42};
        final encoded = ZenEncoder.encode(
          requestData,
          ZenTransportFormat.msgpack,
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/echo'),
          body: encoded,
          headers: {
            'Content-Type': 'application/msgpack',
            zenTransportHeaderName: 'msgpack',
          },
        );

        final response = await pipeline(request);

        expect(response.statusCode, 200);
        final bodyBytes = await response.read().toList();
        final bytes = Uint8List.fromList(
          bodyBytes.expand((chunk) => chunk).toList(),
        );
        final decoded = ZenDecoder.decode(bytes, ZenTransportFormat.msgpack);
        expect(decoded, {'echo': 42});
      });
    });
  });
}
