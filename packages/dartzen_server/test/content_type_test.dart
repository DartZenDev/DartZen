import 'package:dartzen_server/src/handlers/content_handler.dart';
import 'package:dartzen_server/src/zen_content_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

void main() {
  group('Content Type Handling', () {
    test('serves HTML with correct content-type', () async {
      // Arrange: Provider with HTML content
      const provider = MemoryContentProvider({
        'index.html': ZenContent(
          data: '<html><body>Test</body></html>',
          contentType: 'text/html; charset=utf-8',
        ),
      });

      // Act: Create handler and serve content
      const handler = ContentHandler(provider);
      final request = shelf.Request('GET', Uri.parse('http://localhost/'));
      final response = await handler.handle(request, 'index.html');

      // Assert: Check content-type header
      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], contains('text/html'));
    });

    test('serves JSON with correct content-type', () async {
      // Arrange: Provider with JSON content
      const provider = MemoryContentProvider({
        'data.json': ZenContent(
          data: '{"key": "value"}',
          contentType: 'application/json',
        ),
      });

      // Act: Create handler and serve content
      const handler = ContentHandler(provider);
      final request = shelf.Request('GET', Uri.parse('http://localhost/'));
      final response = await handler.handle(request, 'data.json');

      // Assert: Check content-type header
      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('application/json'));
    });

    test('handles mixed content types from single provider', () async {
      // Arrange: Provider with multiple content types
      const provider = MemoryContentProvider({
        'page.html': ZenContent(
          data: '<html><body>Page</body></html>',
          contentType: 'text/html',
        ),
        'data.json': ZenContent(
          data: '{"status": "ok"}',
          contentType: 'application/json',
        ),
        'report.csv': ZenContent(
          data: 'name,value\ntest,123',
          contentType: 'text/csv',
        ),
      });

      // Act & Assert: Each key serves correct content type
      final htmlContent = await provider.getByKey('page.html');
      expect(htmlContent?.contentType, equals('text/html'));

      final jsonContent = await provider.getByKey('data.json');
      expect(jsonContent?.contentType, equals('application/json'));

      final csvContent = await provider.getByKey('report.csv');
      expect(csvContent?.contentType, equals('text/csv'));
    });
  });
}
