import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:test/test.dart';

const bool _isDev = String.fromEnvironment('DZ_ENV') == 'dev';

void main() {
  group('GcsStorageConfig (dev-only checks)', () {
    test('emulatorHost returns override in dev', () {
      final config = GcsStorageConfig(projectId: 'project', bucket: 'bucket');

      expect(config.emulatorHost, isNotNull);
      expect(config.credentialsMode, GcsCredentialsMode.anonymous);
      expect(config.toString(), contains('EMULATOR'));
    }, skip: !_isDev);

    test('throws if emulator host missing in dev', () {
      // When running in dev without an emulator host defined (compile-time),
      // calling emulatorHost (getter) should throw. Tests that depend on a
      // compile-time value should instead pass an explicit override.
      expect(
        () => GcsStorageConfig(projectId: 'p', bucket: 'b').emulatorHost,
        throwsA(isA<StateError>()),
      );
    }, skip: !_isDev);
  });
}
