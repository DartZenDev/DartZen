import 'package:dartzen_infrastructure_storage/dartzen_infrastructure_storage.dart';
import 'package:gcloud/storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage extends Mock implements Storage {}

class MockBucket extends Mock implements Bucket {}

void main() {
  group('GcsStaticContentProvider', () {
    late MockStorage mockStorage;
    late MockBucket mockBucket;
    late GcsStaticContentProvider provider;

    setUp(() {
      mockStorage = MockStorage();
      mockBucket = MockBucket();
      provider = GcsStaticContentProvider(
        storage: mockStorage,
        bucket: 'test-bucket',
      );
    });

    test('returns content when object exists', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('test-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [72, 101, 108, 108, 111], // "Hello"
        ]),
      );

      final result = await provider.getByKey('test-key');

      expect(result, equals('Hello'));
      verify(() => mockStorage.bucket('test-bucket')).called(1);
      verify(() => mockBucket.read('test-key')).called(1);
    });

    test('returns null when object does not exist', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('missing-key'),
      ).thenThrow(Exception('Not found'));

      final result = await provider.getByKey('missing-key');

      expect(result, isNull);
      verify(() => mockStorage.bucket('test-bucket')).called(1);
      verify(() => mockBucket.read('missing-key')).called(1);
    });

    test('applies prefix when configured', () async {
      final providerWithPrefix = GcsStaticContentProvider(
        storage: mockStorage,
        bucket: 'test-bucket',
        prefix: 'public/',
      );

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('public/test-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [84, 101, 115, 116], // "Test"
        ]),
      );

      final result = await providerWithPrefix.getByKey('test-key');

      expect(result, equals('Test'));
      verify(() => mockBucket.read('public/test-key')).called(1);
    });

    test('handles multi-chunk streams', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('chunked-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [72, 101], // "He"
          [108, 108], // "ll"
          [111], // "o"
        ]),
      );

      final result = await provider.getByKey('chunked-key');

      expect(result, equals('Hello'));
    });

    test('returns null on any error', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(
        () => mockBucket.read('error-key'),
      ).thenThrow(StateError('Access denied'));

      final result = await provider.getByKey('error-key');

      expect(result, isNull);
    });

    test('handles empty key values', () async {
      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('')).thenAnswer(
        (_) => Stream.fromIterable([
          [69, 109, 112, 116, 121], // "Empty"
        ]),
      );

      final result = await provider.getByKey('');

      expect(result, equals('Empty'));
      verify(() => mockBucket.read('')).called(1);
    });

    test('handles empty prefix correctly', () async {
      final providerWithEmptyPrefix = GcsStaticContentProvider(
        storage: mockStorage,
        bucket: 'test-bucket',
        prefix: '',
      );

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('test-key')).thenAnswer(
        (_) => Stream.fromIterable([
          [84, 101, 115, 116], // "Test"
        ]),
      );

      final result = await providerWithEmptyPrefix.getByKey('test-key');

      expect(result, equals('Test'));
      verify(() => mockBucket.read('test-key')).called(1);
    });

    test('combines prefix and key correctly', () async {
      final providerWithPrefix = GcsStaticContentProvider(
        storage: mockStorage,
        bucket: 'test-bucket',
        prefix: 'static/',
      );

      when(() => mockStorage.bucket('test-bucket')).thenReturn(mockBucket);
      when(() => mockBucket.read('static/terms')).thenAnswer(
        (_) => Stream.fromIterable([
          [84, 101, 114, 109, 115], // "Terms"
        ]),
      );

      final result = await providerWithPrefix.getByKey('terms');

      expect(result, equals('Terms'));
      verify(() => mockBucket.read('static/terms')).called(1);
    });
  });
}
