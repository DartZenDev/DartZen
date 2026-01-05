import 'dart:convert';
import 'dart:typed_data';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Additional low-level behavior tests migrated from firebase_storage_reader_error_test.dart
class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);
  final Future<http.Response> Function(Uri url) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = await handler(request.url);
    final stream = Stream<List<int>>.fromIterable([resp.bodyBytes]);
    return http.StreamedResponse(
      stream,
      resp.statusCode,
      headers: resp.headers,
      reasonPhrase: resp.reasonPhrase,
      request: request,
    );
  }
}

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

void main() {
  setUpAll(() {
    // `test/test_setup.dart` also registers a BaseRequest fake; harmless to call again
    registerFallbackValue(Uri());
  });

  group('FirebaseStorageReader', () {
    late MockHttpClient mockClient;
    late FirebaseStorageReader reader;
    const bucket = 'test-bucket';
    const emulatorHost = 'localhost:9199';

    setUp(() {
      mockClient = MockHttpClient();
      reader = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: bucket,
          emulatorHost: emulatorHost,
        ),
        httpClient: mockClient,
      );
    });

    test('returns object with null contentType if header missing', () async {
      final mockResponse = MockResponse();
      when(() => mockClient.get(any())).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(
        () => mockResponse.bodyBytes,
      ).thenReturn(Uint8List.fromList([65, 66, 67]));
      when(() => mockResponse.headers).thenReturn({});

      final result = await reader.read('file.txt');
      expect(result, isNotNull);
      expect(result!.bytes, equals([65, 66, 67]));
      expect(result.contentType, isNull);
    });

    test('returns object when found', () async {
      final mockResponse = MockResponse();
      when(() => mockClient.get(any())).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(
        () => mockResponse.bodyBytes,
      ).thenReturn(Uint8List.fromList([65, 66, 67]));
      when(
        () => mockResponse.headers,
      ).thenReturn({'content-type': 'text/plain'});

      final result = await reader.read('file.txt');
      expect(result, isNotNull);
      expect(result!.bytes, equals([65, 66, 67]));
      expect(result.contentType, equals('text/plain'));
    });

    test('returns null when not found (404)', () async {
      final mockResponse = MockResponse();
      when(() => mockClient.get(any())).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.bodyBytes).thenReturn(Uint8List(0));
      when(() => mockResponse.headers).thenReturn({});

      final result = await reader.read('missing.txt');
      expect(result, isNull);
    });

    test('throws StorageReadException for non-200/404', () async {
      final mockResponse = MockResponse();
      when(() => mockClient.get(any())).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(500);
      when(() => mockResponse.reasonPhrase).thenReturn('Internal Error');
      when(() => mockResponse.bodyBytes).thenReturn(Uint8List(0));
      when(() => mockResponse.headers).thenReturn({});

      expect(reader.read('error.txt'), throwsA(isA<StorageReadException>()));
    });

    test('throws StorageReadException for http error', () async {
      when(() => mockClient.get(any())).thenThrow(Exception('Network error'));
      expect(reader.read('network.txt'), throwsA(isA<StorageReadException>()));
    });

    test('applies prefix when configured', () async {
      // Recreate reader with prefix in config
      reader = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: bucket,
          prefix: 'images/',
          emulatorHost: emulatorHost,
        ),
        httpClient: mockClient,
      );

      final mockResponse = MockResponse();
      when(
        () => mockClient.get(captureAny()),
      ).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(
        () => mockResponse.bodyBytes,
      ).thenReturn(Uint8List.fromList([1, 2, 3]));
      when(() => mockResponse.headers).thenReturn({});

      final result = await reader.read('file.txt');
      expect(result, isNotNull);

      // Verify the request was made to a URL containing the prefixed object name
      final captured = verify(() => mockClient.get(captureAny())).captured;
      expect(captured.isNotEmpty, isTrue);
      final uri = captured.first as Uri;
      // The object name is URL-encoded in the request path ("/o/images%2Ffile.txt").
      expect(uri.path, contains('images%2Ffile.txt'));
    });

    test('close closes the http client', () async {
      final mockClient2 = MockHttpClient();
      final reader2 = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: bucket,
          emulatorHost: emulatorHost,
        ),
        httpClient: mockClient2,
      );

      reader2.close();
      verify(mockClient2.close).called(1);
    });
  });

  group('FirebaseStorageReader (low-level client behavior)', () {
    test(
      'returns StorageObject on 200 with content-type (fake client)',
      () async {
        final fake = _FakeClient(
          (_) async => http.Response(
            'hello',
            200,
            headers: {'content-type': 'text/plain'},
          ),
        );
        final reader = FirebaseStorageReader(
          config: FirebaseStorageConfig(
            bucket: 'b',
            emulatorHost: 'localhost:8080',
          ),
          httpClient: fake,
        );

        final obj = await reader.read('file.txt');
        expect(obj, isNotNull);
        expect(obj!.contentType, 'text/plain');
        expect(obj.bytes, utf8.encode('hello'));
      },
    );

    test('returns null on 404 (fake client)', () async {
      final fake = _FakeClient((_) async => http.Response('not found', 404));
      final reader = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: 'b',
          emulatorHost: 'localhost:8080',
        ),
        httpClient: fake,
      );

      final obj = await reader.read('missing.txt');
      expect(obj, isNull);
    });

    test('throws StorageReadException on 500 (fake client)', () async {
      final fake = _FakeClient(
        (_) async => http.Response('error', 500, reasonPhrase: 'Server Error'),
      );
      final reader = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: 'b',
          emulatorHost: 'localhost:8080',
        ),
        httpClient: fake,
      );

      expect(
        () => reader.read('error.txt'),
        throwsA(isA<StorageReadException>()),
      );
    });

    test('wraps network exceptions (fake client)', () async {
      final fake = _FakeClient((_) async => throw Exception('network'));
      final reader = FirebaseStorageReader(
        config: FirebaseStorageConfig(
          bucket: 'b',
          emulatorHost: 'localhost:8080',
        ),
        httpClient: fake,
      );

      expect(
        () => reader.read('net.txt'),
        throwsA(isA<StorageReadException>()),
      );
    });
  });
}
