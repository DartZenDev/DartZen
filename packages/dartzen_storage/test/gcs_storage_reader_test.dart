import 'dart:async';

import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage extends Mock implements Storage {}

class MockBucket extends Mock implements Bucket {}

class MockObjectInfo extends Mock implements ObjectInfo {}

class MockObjectMetadata extends Mock implements ObjectMetadata {}

// Emulator internals helpers (moved to top-level)
class MockInnerClient extends Mock implements http.Client {}

class _BaseRequestFake extends Fake implements http.BaseRequest {}

class _FakeBaseRequest extends http.BaseRequest {
  _FakeBaseRequest(super.method, super.url, this._body);
  final List<int> _body;

  @override
  http.ByteStream finalize() {
    try {
      super.finalize();
    } catch (_) {}
    return http.ByteStream.fromBytes(_body);
  }
}

void _registerEmulatorFallbacks() {
  try {
    registerFallbackValue(_BaseRequestFake());
  } catch (_) {}
}

void main() {
  group('GcsStorageReader', () {
    late MockStorage mockStorage;
    late MockBucket mockBucket;
    late GcsStorageReader reader;

    setUp(() {
      mockStorage = MockStorage();
      mockBucket = MockBucket();
      reader = GcsStorageReader(
        config: GcsStorageConfig(
          projectId: 'test-project',
          bucket: 'test-bucket',
        ),
        storage: mockStorage,
      );
    });

    test('returns object when it exists', () async {
      final mockInfo = MockObjectInfo();
      final mockMetadata = MockObjectMetadata();

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('test-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [72, 101, 108, 108, 111], // "Hello"
        ]),
      );
      when(() => mockBucket.info('test-key')).thenAnswer((_) async => mockInfo);
      when(() => mockInfo.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.contentType).thenReturn('text/plain');

      final result = await reader.read('test-key');

      expect(result, isNotNull);
      expect(result!.asString(), equals('Hello'));
      expect(result.contentType, equals('text/plain'));
      expect(result.size, equals(5));
    });

    test('returns null when object does not exist (404)', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('missing-key'),
      ).thenThrow(storage_api.DetailedApiRequestError(404, 'Object not found'));

      final result = await reader.read('missing-key');

      expect(result, isNull);
    });

    test('applies prefix when configured', () async {
      final readerWithPrefix = GcsStorageReader(
        config: GcsStorageConfig(
          projectId: 'test-project',
          bucket: 'test-bucket',
          prefix: 'data/',
        ),
        storage: mockStorage,
      );

      final mockInfo = MockObjectInfo();
      final mockMetadata = MockObjectMetadata();

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('data/file.json')).thenAnswer(
        (_) => Stream.fromIterable([
          [123, 125], // "{}"
        ]),
      );
      when(
        () => mockBucket.info('data/file.json'),
      ).thenAnswer((_) async => mockInfo);
      when(() => mockInfo.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.contentType).thenReturn('application/json');

      final result = await readerWithPrefix.read('file.json');

      expect(result, isNotNull);
      expect(result!.asString(), equals('{}'));
      expect(result.contentType, equals('application/json'));
      verify(() => mockBucket.read('data/file.json')).called(1);
    });

    test('handles multi-chunk streams', () async {
      final mockInfo = MockObjectInfo();
      final mockMetadata = MockObjectMetadata();

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('chunked-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [72, 101], // "He"
          [108, 108], // "ll"
          [111], // "o"
        ]),
      );
      when(
        () => mockBucket.info('chunked-key'),
      ).thenAnswer((_) async => mockInfo);
      when(() => mockInfo.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.contentType).thenReturn('text/plain');

      final result = await reader.read('chunked-key');

      expect(result, isNotNull);
      expect(result!.asString(), equals('Hello'));
      expect(result.size, equals(5));
    });

    test('returns null content type when metadata fetch fails', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('test-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [72, 101, 108, 108, 111],
        ]),
      );
      when(
        () => mockBucket.info('test-key'),
      ).thenThrow(Exception('Metadata unavailable'));

      final result = await reader.read('test-key');

      expect(result, isNotNull);
      expect(result!.asString(), equals('Hello'));
      expect(result.contentType, isNull);
    });

    test('handles empty key values', () async {
      final mockInfo = MockObjectInfo();
      final mockMetadata = MockObjectMetadata();

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('')).thenAnswer(
        (_) => Stream.fromIterable([
          [69, 109, 112, 116, 121], // "Empty"
        ]),
      );
      when(() => mockBucket.info('')).thenAnswer((_) async => mockInfo);
      when(() => mockInfo.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.contentType).thenReturn('text/plain');

      final result = await reader.read('');

      expect(result, isNotNull);
      expect(result!.asString(), equals('Empty'));
    });

    test('throws on permission error (403)', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('forbidden-key')).thenThrow(
        storage_api.DetailedApiRequestError(403, 'Permission denied'),
      );

      expect(
        () => reader.read('forbidden-key'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('throws on server error (500)', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('error-key')).thenThrow(
        storage_api.DetailedApiRequestError(500, 'Internal server error'),
      );

      expect(
        () => reader.read('error-key'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('throws on network error', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('network-error'),
      ).thenThrow(StateError('Network failure'));

      expect(() => reader.read('network-error'), throwsA(isA<StateError>()));
    });
  });

  // --- Additional tests (migrated from gcs_storage_reader_more_test.dart)
  group('GcsStorageReader additional branches', () {
    late MockStorage mockStorage2;
    late MockBucket mockBucket2;
    late GcsStorageReader reader2;

    setUp(() {
      mockStorage2 = MockStorage();
      mockBucket2 = MockBucket();
      reader2 = GcsStorageReader(
        config: GcsStorageConfig(projectId: 'p', bucket: 'b'),
        storage: mockStorage2,
      );
    });

    test('rethrows DetailedApiRequestError for non-404 status', () async {
      when(() => mockStorage2.bucket('b')).thenReturn(mockBucket2);
      when(
        () => mockBucket2.read('k'),
      ).thenThrow(storage_api.DetailedApiRequestError(500, 'Internal error'));

      expect(
        () => reader2.read('k'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('throws on 403 DetailedApiRequestError', () async {
      when(() => mockStorage2.bucket('b')).thenReturn(mockBucket2);
      when(
        () => mockBucket2.read('forbidden'),
      ).thenThrow(storage_api.DetailedApiRequestError(403, 'Forbidden'));

      expect(
        () => reader2.read('forbidden'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('info returns metadata with null contentType', () async {
      final mockInfo = MockObjectInfo();
      final mockMeta = MockObjectMetadata();

      when(() => mockStorage2.bucket('b')).thenReturn(mockBucket2);
      when(() => mockBucket2.read('nct')).thenAnswer(
        (_) => Stream.fromIterable([
          [1, 2, 3],
        ]),
      );
      when(() => mockBucket2.info('nct')).thenAnswer((_) async => mockInfo);
      when(() => mockInfo.metadata).thenReturn(mockMeta);
      when(() => mockMeta.contentType).thenReturn(null);

      final res = await reader2.read('nct');
      expect(res, isNotNull);
      expect(res!.contentType, isNull);
    });

    test(
      'empty stream returns empty bytes and null contentType when info fails',
      () async {
        when(() => mockStorage2.bucket('b')).thenReturn(mockBucket2);
        when(
          () => mockBucket2.read('empty'),
        ).thenAnswer((_) => Stream<List<int>>.fromIterable([]));
        when(() => mockBucket2.info('empty')).thenThrow(Exception('no meta'));

        final res = await reader2.read('empty');
        expect(res, isNotNull);
        expect(res!.bytes, isEmpty);
        expect(res.contentType, isNull);
      },
    );
  });

  // --- Emulator internals tests (migrated from gcs_storage_reader_internal_test.dart)

  group('EmulatorHttpClient internals', () {
    setUpAll(_registerEmulatorFallbacks);

    late MockInnerClient inner;
    late EmulatorHttpClient client;

    setUp(() {
      inner = MockInnerClient();
      client = EmulatorHttpClient(inner, 'localhost:9090');
    });

    test('for http.Request copies bodyBytes and redirects host/port', () async {
      final req = http.Request('POST', Uri.parse('https://example.com/path'));
      req.bodyBytes = [1, 2, 3];

      when(() => inner.send(any())).thenAnswer((invocation) async {
        final r = invocation.positionalArguments.first as http.BaseRequest;
        expect(r.url.host, equals('localhost'));
        expect(r.url.port, equals(9090));
        if (r is http.Request) {
          expect(r.bodyBytes, equals([1, 2, 3]));
        }
        final stream = Stream.fromIterable([<int>[]]);
        return http.StreamedResponse(stream, 200);
      });

      final streamed = await client.send(req);
      expect(streamed.statusCode, equals(200));
    });

    test('for non-Request uses finalize().bytesToString()', () async {
      final fr = _FakeBaseRequest(
        'PUT',
        Uri.parse('https://example.com/other'),
        [97, 98, 99],
      );

      when(() => inner.send(any())).thenAnswer((invocation) async {
        final r = invocation.positionalArguments.first as http.BaseRequest;
        expect(r.url.host, equals('localhost'));
        expect(r.url.port, equals(9090));
        if (r is http.Request) {
          expect(r.bodyBytes, equals([97, 98, 99]));
        }
        final stream = Stream.fromIterable([<int>[]]);
        return http.StreamedResponse(stream, 200);
      });

      final streamed = await client.send(fr);
      expect(streamed.statusCode, equals(200));
    });

    test('get delegates to send and returns StreamedResponse', () async {
      when(() => inner.send(any())).thenAnswer((_) async {
        final stream = Stream.fromIterable([<int>[]]);
        return http.StreamedResponse(stream, 204);
      });

      final resp = await client.get(Uri.parse('https://example.com/'));
      expect(resp.statusCode, equals(204));
    });
  });
}
