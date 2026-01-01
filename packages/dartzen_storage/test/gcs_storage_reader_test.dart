import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage extends Mock implements Storage {}

class MockBucket extends Mock implements Bucket {}

class MockObjectInfo extends Mock implements ObjectInfo {}

class MockObjectMetadata extends Mock implements ObjectMetadata {}

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
}
