import 'package:dartzen_server/dartzen_server.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('ZenServerApplication', () {
    late ZenServerApplication app;
    const port = 8081;

    setUp(() {
      app = ZenServerApplication(
        config: const ZenServerConfig(
          port: port,
          staticContentProvider: MemoryStaticContentProvider(
            {
            'terms': '<html><body><h1>Terms & Conditions</h1></body></html>',
          },
          ),
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
  });
}
