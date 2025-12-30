import 'dart:io';

import 'package:dartzen_server/dartzen_server.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

void main() {
  group('ZenServerApplication', () {
    late ZenServerApplication app;
    const port = 8081;

    setUp(() {
      app = ZenServerApplication(
        config: const ZenServerConfig(
          port: port,
          contentProvider: MemoryContentProvider({
            'terms.html':
                '<html><body><h1>Terms & Conditions</h1></body></html>',
          }),
          contentRoutes: {'/terms': 'terms.html'},
        ),
      );
    });

    tearDown(() async {
      await app.stop();
    });

    test('starts and responds to health check', () async {
      await app.run();

      final response = await http.get(
        Uri.parse('http://localhost:$port/health'),
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('ok'));
    });

    test('serves terms and conditions', () async {
      await app.run();

      final response = await http.get(
        Uri.parse('http://localhost:$port/terms'),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('text/html'));
      expect(response.body, contains('Terms & Conditions'));
    });

    test('executes lifecycle hooks', () async {
      var startupCalled = false;
      var shutdownCalled = false;

      app.onStartup(() => startupCalled = true);
      app.onShutdown(() => shutdownCalled = true);

      await app.run();
      expect(startupCalled, isTrue);

      await app.stop();
      expect(shutdownCalled, isTrue);
    });

    test('registers routes correctly', () async {
      final router = Router();
      router.get('/custom', (Request request) => Response.ok('Custom route'));

      final pipeline = const Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      final server0 = await io.serve(
        pipeline,
        InternetAddress.loopbackIPv4,
        port,
      );

      final response = await http.get(
        Uri.parse('http://localhost:$port/custom'),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'Custom route');

      await server0.close();
    });

    test('executes middleware in correct order', () async {
      final middlewareOrder = <String>[];

      final pipeline = const Pipeline()
          .addMiddleware(
            (Handler innerHandler) => (Request request) {
              middlewareOrder.add('middleware1');
              return innerHandler(request);
            },
          )
          .addMiddleware(
            (Handler innerHandler) => (Request request) {
              middlewareOrder.add('middleware2');
              return innerHandler(request);
            },
          )
          .addHandler((Request request) {
            middlewareOrder.add('handler');
            return Response.ok('Middleware test');
          });

      final server = await io.serve(
        pipeline,
        InternetAddress.loopbackIPv4,
        port,
      );

      final response = await http.get(Uri.parse('http://localhost:$port/test'));
      expect(response.statusCode, 200);
      expect(response.body, 'Middleware test');
      expect(middlewareOrder, ['middleware1', 'middleware2', 'handler']);

      await server.close();
    });
  });
}
