import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_demo_server/src/services/auth_service.dart';
import 'package:test/test.dart';

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
      expect(
        (error as ZenValidationError).message,
        AuthError.invalidEmailFormat.code,
      );
    });

    test('rejects empty password', () async {
      final result = await service.authenticate(
        email: 'user@example.com',
        password: '',
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenValidationError>());
      expect(
        (error as ZenValidationError).message,
        AuthError.invalidCredentials.code,
      );
    });

    test('rejects email with missing @ symbol', () async {
      final result = await service.authenticate(
        email: 'invalidemail.com',
        password: 'secret',
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenValidationError>());
      expect(
        (error as ZenValidationError).message,
        AuthError.invalidEmailFormat.code,
      );
    });

    test('rejects email with missing domain', () async {
      final result = await service.authenticate(
        email: 'user@',
        password: 'secret',
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenValidationError>());
      expect(
        (error as ZenValidationError).message,
        AuthError.invalidEmailFormat.code,
      );
    });

    test('rejects empty email', () async {
      final result = await service.authenticate(email: '', password: 'secret');

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenValidationError>());
      expect(
        (error as ZenValidationError).message,
        AuthError.invalidEmailFormat.code,
      );
    });

    test('accepts valid email format', () async {
      // This will fail at the network level, but not at validation
      final result = await service.authenticate(
        email: 'valid@example.com',
        password: 'secret123',
      );

      // Should fail due to network/auth error, not validation
      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenUnauthorizedError>());
      expect(
        (error as ZenUnauthorizedError).message,
        AuthError.authenticationFailed.code,
      );
    });

    test('validates complex valid email addresses', () async {
      final result = await service.authenticate(
        email: 'user+tag@example.co.uk',
        password: 'secret123',
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<ZenUnauthorizedError>());
    });
  });

  group('AuthError enum', () {
    test('all AuthError enum values have correct code', () {
      expect(AuthError.missingAuthHeader.code, 'missingAuthHeader');
      expect(AuthError.invalidToken.code, 'invalidToken');
      expect(AuthError.authenticationFailed.code, 'authenticationFailed');
      expect(AuthError.invalidCredentials.code, 'invalidCredentials');
      expect(AuthError.invalidEmailFormat.code, 'invalidEmailFormat');
    });
  });
}
