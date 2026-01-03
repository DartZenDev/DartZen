import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage2 extends Mock implements Storage {}

class MockBucket2 extends Mock implements Bucket {}

class MockObjectInfo2 extends Mock implements ObjectInfo {}

class MockObjectMetadata2 extends Mock implements ObjectMetadata {}

void main() {
  group('GcsStorageReader additional branches', () {
    late MockStorage2 mockStorage;
    late MockBucket2 mockBucket;
    late GcsStorageReader reader;

    setUp(() {
      mockStorage = MockStorage2();
      mockBucket = MockBucket2();
      reader = GcsStorageReader(
        config: GcsStorageConfig(projectId: 'p', bucket: 'b'),
        storage: mockStorage,
      );
    });

    test('rethrows DetailedApiRequestError for non-404 status', () async {
      when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('k'),
      ).thenThrow(storage_api.DetailedApiRequestError(500, 'Internal error'));

      expect(
        () => reader.read('k'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('throws on 403 DetailedApiRequestError', () async {
      when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('forbidden'),
      ).thenThrow(storage_api.DetailedApiRequestError(403, 'Forbidden'));

      expect(
        () => reader.read('forbidden'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('info returns metadata with null contentType', () async {
      final mockInfo = MockObjectInfo2();
      final mockMeta = MockObjectMetadata2();

      when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
      when(() => mockBucket.read('nct')).thenAnswer(
        (_) => Stream.fromIterable([
          [1, 2, 3],
        ]),
      );
      when(() => mockBucket.info('nct')).thenAnswer((_) async => mockInfo);
      when(() => mockInfo.metadata).thenReturn(mockMeta);
      when(() => mockMeta.contentType).thenReturn(null);

      final res = await reader.read('nct');
      expect(res, isNotNull);
      expect(res!.contentType, isNull);
    });

    test(
      'empty stream returns empty bytes and null contentType when info fails',
      () async {
        when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
        when(
          () => mockBucket.read('empty'),
        ).thenAnswer((_) => Stream<List<int>>.fromIterable([]));
        when(() => mockBucket.info('empty')).thenThrow(Exception('no meta'));

        final res = await reader.read('empty');
        expect(res, isNotNull);
        expect(res!.bytes, isEmpty);
        expect(res.contentType, isNull);
      },
    );
  });
}
