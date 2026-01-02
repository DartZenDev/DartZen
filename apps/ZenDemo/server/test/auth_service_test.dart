import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';
import 'package:zen_demo_server/src/services/auth_service.dart';

void main() {
  group('AuthService validation', () {
    final service = AuthService(authUrl: Uri.parse('http://localhost'));

    test('rejects invalid email format', () async {
      final result = await service.authenticate(
        email: 'invalid-email',
        password: 'secret',
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenValidationError>());
      expect((error as ZenValidationError).message,
          AuthError.invalidEmailFormat.code);
    });

    test('rejects empty password', () async {
      final result = await service.authenticate(
        email: 'user@example.com',
        password: '',
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenValidationError>());
      expect((error as ZenValidationError).message,
          AuthError.invalidCredentials.code);
    });
  });
}
