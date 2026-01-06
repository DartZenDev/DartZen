import 'dart:convert';
import 'dart:io';

import 'package:dartzen_server/src/handlers/content_handler.dart';
import 'package:dartzen_server/src/zen_content_provider.dart';
import 'package:dartzen_storage/dartzen_storage.dart';
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

    test('returns 404 when content missing and no fallback', () async {
      // Arrange: empty provider
      const provider = MemoryContentProvider({});
      const handler = ContentHandler(provider);

      // Act
      final request = shelf.Request('GET', Uri.parse('http://localhost/'));
      final response = await handler.handle(request, 'missing.txt');

      // Assert
      expect(response.statusCode, equals(404));
    });

    test('uses fallback key when primary missing', () async {
      // Arrange: provider with only fallback key
      const provider = MemoryContentProvider({
        'fallback.html': ZenContent(
          data: '<p>FB</p>',
          contentType: 'text/html',
        ),
      });
      const handler = ContentHandler(provider, fallbackKey: 'fallback.html');

      // Act
      final request = shelf.Request('GET', Uri.parse('http://localhost/'));
      final response = await handler.handle(request, 'missing.html');

      // Assert
      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], contains('text/html'));
      expect(response.readAsString(), completion(contains('FB')));
    });

    test('FileContentProvider infers content types (css)', () async {
      // Arrange: create a temporary file with .css extension
      final dir = await Directory.systemTemp.createTemp('dz_test_');
      final file = File('${dir.path}/styles.css')..writeAsStringSync('body{}');
      final provider = FileContentProvider(dir.path);

      // Act
      final content = await provider.getByKey('styles.css');

      // Assert
      expect(content, isNotNull);
      expect(content?.contentType, contains('text/css'));

      // cleanup
      await file.delete();
      await dir.delete();
    });

    test('MemoryContentProvider throws for invalid value types', () async {
      // Arrange: invalid value in map
      const provider = MemoryContentProvider({'k': 123 as Object});

      // Act / Assert
      expect(provider.getByKey('k'), throwsA(isA<ArgumentError>()));
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

    test('StorageContentProvider returns null when object missing', () async {
      // Arrange: fake reader returns null
      final reader = _FakeReader(null);
      final provider = StorageContentProvider(reader: reader);

      // Act
      final content = await provider.getByKey('nope');

      // Assert
      expect(content, isNull);
    });

    test('StorageContentProvider defaults unknown content-type', () async {
      // Arrange: reader returns object with null contentType
      final obj = StorageObject(bytes: utf8.encode('hello'));
      final reader = _FakeReader(obj);
      final provider = StorageContentProvider(reader: reader);

      // Act
      final content = await provider.getByKey('doc');

      // Assert
      expect(content, isNotNull);
      expect(content?.data, equals('hello'));
      expect(content?.contentType, equals('application/octet-stream'));
    });

    test('FileContentProvider infers .js and .pdf content types', () async {
      final dir = await Directory.systemTemp.createTemp('dz_test_js_pdf_');
      final js = File('${dir.path}/app.js')
        ..writeAsStringSync('console.log(1);');
      final pdf = File('${dir.path}/doc.pdf')..writeAsStringSync('PDF TEXT');
      final provider = FileContentProvider(dir.path);

      final jsContent = await provider.getByKey('app.js');
      final pdfContent = await provider.getByKey('doc.pdf');

      expect(jsContent?.contentType, equals('application/javascript'));
      expect(pdfContent?.contentType, equals('application/pdf'));

      await js.delete();
      await pdf.delete();
      await dir.delete();
    });
  });
}

class _FakeReader implements ZenStorageReader {
  _FakeReader(this._obj);

  final StorageObject? _obj;

  @override
  Future<StorageObject?> read(String key) async => _obj;
}
