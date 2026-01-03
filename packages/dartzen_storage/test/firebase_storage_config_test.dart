import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseStorageConfig', () {
    test('constructs with valid host', () {
      final config = FirebaseStorageConfig(
        bucket: 'bucket',
        emulatorHost: 'localhost:9199',
      );
      expect(config.bucket, 'bucket');
      expect(config.emulatorHost, 'localhost:9199');
    });

    test('throws if emulatorHost is empty', () {
      expect(
        () => FirebaseStorageConfig(bucket: 'bucket', emulatorHost: ''),
        throwsA(isA<StateError>()),
      );
    });

    test('toString returns formatted string', () {
      final config = FirebaseStorageConfig(
        bucket: 'bucket',
        emulatorHost: 'localhost:9199',
      );
      expect(config.toString(), contains('bucket: bucket'));
    });

    test('throws StateError if emulatorHost is empty', () {
      expect(
        () => FirebaseStorageConfig(bucket: 'test-bucket', emulatorHost: ''),
        throwsA(isA<StateError>()),
      );
    });

    test('creates config with valid emulatorHost', () {
      final config = FirebaseStorageConfig(
        bucket: 'test-bucket',
        emulatorHost: 'localhost:9199',
      );

      expect(config.bucket, 'test-bucket');
      expect(config.emulatorHost, 'localhost:9199');
    });
  });
}
