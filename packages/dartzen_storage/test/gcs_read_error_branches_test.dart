import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorageX extends Mock implements Storage {}

class MockBucketX extends Mock implements Bucket {}

void main() {
  group('GcsStorageReader read() error branches', () {
    late MockStorageX mockStorage;
    late MockBucketX mockBucket;

    setUp(() {
      mockStorage = MockStorageX();
      mockBucket = MockBucketX();
    });

    test('rethrows DetailedApiRequestError when status != 404', () async {
      final reader = GcsStorageReader(
        config: GcsStorageConfig(projectId: 'p', bucket: 'b'),
        storage: mockStorage,
      );

      when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('k'),
      ).thenThrow(storage_api.DetailedApiRequestError(500, 'err'));

      await expectLater(
        reader.read('k'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('throws on 403 DetailedApiRequestError', () async {
      final reader = GcsStorageReader(
        config: GcsStorageConfig(projectId: 'p', bucket: 'b'),
        storage: mockStorage,
      );

      when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('forbidden'),
      ).thenThrow(storage_api.DetailedApiRequestError(403, 'forbidden'));

      await expectLater(
        reader.read('forbidden'),
        throwsA(isA<storage_api.DetailedApiRequestError>()),
      );
    });

    test('rethrows generic exceptions from read()', () async {
      final reader = GcsStorageReader(
        config: GcsStorageConfig(projectId: 'p', bucket: 'b'),
        storage: mockStorage,
      );

      when(() => mockStorage.bucket('b')).thenReturn(mockBucket);
      when(() => mockBucket.read('boom')).thenThrow(Exception('boom'));

      await expectLater(reader.read('boom'), throwsA(isA<Exception>()));
    });
  });
}
