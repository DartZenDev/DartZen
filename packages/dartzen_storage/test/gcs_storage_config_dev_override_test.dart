import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:test/test.dart';

const bool _isTest = dzIsTest;

void main() {
  group('GcsStorageConfig (test - override)', () {
    test('emulatorHost returns override in test', () {
      final config = GcsStorageConfig(
        projectId: 'project',
        bucket: 'bucket',
        emulatorHost: 'localhost:9090',
      );

      expect(config.emulatorHost, 'localhost:9090');
      expect(config.credentialsMode, GcsCredentialsMode.anonymous);
      expect(config.toString(), contains('EMULATOR'));
    }, skip: !_isTest);
  });
}
