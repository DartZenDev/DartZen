import 'package:dartzen_server_transport/dartzen_server_transport.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('transportMiddleware', () {
    test('negotiates JSON format from header', () async {
      final middleware = transportMiddleware();
      final handler = middleware((request) {
        final format =
            request.context['transport_format'] as ZenTransportFormat;
        expect(format, equals(ZenTransportFormat.json));
        return Response.ok('');
      });

      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {zenTransportHeaderName: 'json'},
      );

      await handler(request);
    });

    test('negotiates msgpack format from header', () async {
      final middleware = transportMiddleware();
      final handler = middleware((request) {
        final format =
            request.context['transport_format'] as ZenTransportFormat;
        expect(format, equals(ZenTransportFormat.msgpack));
        return Response.ok('');
      });

      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {zenTransportHeaderName: 'msgpack'},
      );

      await handler(request);
    });

    test('defaults to JSON when no header present', () async {
      final middleware = transportMiddleware();
      final handler = middleware((request) {
        final format =
            request.context['transport_format'] as ZenTransportFormat;
        expect(format, equals(ZenTransportFormat.json));
        return Response.ok('');
      });

      final request = Request('GET', Uri.parse('http://localhost/'));
      await handler(request);
    });

    test('zenResponse creates response with context', () {
      final response = zenResponse(200, {'test': 'data'});
      expect(response.statusCode, equals(200));
      expect(response.context['zen_data'], equals({'test': 'data'}));
    });

    test('zenResponse accepts custom headers', () {
      final response = zenResponse(
        200,
        {'test': 'data'},
        headers: {'X-Custom': 'value'},
      );
      expect(response.headers['X-Custom'], equals('value'));
    });
  });
}
