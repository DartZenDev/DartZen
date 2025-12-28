import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';
import 'package:test/test.dart';

void main() {
  group('AuthClaims', () {
    test('creates instance with all fields', () {
      const claims = AuthClaims(
        subject: 'test-subject-123',
        providerId: 'google.com',
        email: 'test@example.com',
        emailVerified: true,
        issuedAt: 1234567890,
        expiresAt: 1234567900,
      );

      expect(claims.subject, 'test-subject-123');
      expect(claims.providerId, 'google.com');
      expect(claims.email, 'test@example.com');
      expect(claims.emailVerified, true);
      expect(claims.issuedAt, 1234567890);
      expect(claims.expiresAt, 1234567900);
    });

    test('creates instance with minimal fields', () {
      const claims = AuthClaims(
        subject: 'test-subject-123',
        providerId: 'google.com',
      );

      expect(claims.subject, 'test-subject-123');
      expect(claims.providerId, 'google.com');
      expect(claims.email, null);
      expect(claims.emailVerified, false);
      expect(claims.issuedAt, null);
      expect(claims.expiresAt, null);
    });

    test('parses from standard JWT claims map', () {
      final claimsMap = {
        'sub': 'jwt-subject-456',
        'firebase': {'sign_in_provider': 'github.com'},
        'email': 'jwt@example.com',
        'email_verified': true,
        'iat': 1111111111,
        'exp': 2222222222,
      };

      final claims = AuthClaims.fromMap(claimsMap);

      expect(claims, isNotNull);
      expect(claims!.subject, 'jwt-subject-456');
      expect(claims.providerId, 'github.com');
      expect(claims.email, 'jwt@example.com');
      expect(claims.emailVerified, true);
      expect(claims.issuedAt, 1111111111);
      expect(claims.expiresAt, 2222222222);
    });

    test('parses from alternative claim fields', () {
      final claimsMap = {
        'subject': 'alt-subject-789',
        'provider_id': 'facebook.com',
        'email': 'alt@example.com',
      };

      final claims = AuthClaims.fromMap(claimsMap);

      expect(claims, isNotNull);
      expect(claims!.subject, 'alt-subject-789');
      expect(claims.providerId, 'facebook.com');
      expect(claims.email, 'alt@example.com');
    });

    test('returns null when subject is missing', () {
      final claimsMap = {
        'provider_id': 'google.com',
        'email': 'test@example.com',
      };

      final claims = AuthClaims.fromMap(claimsMap);

      expect(claims, isNull);
    });

    test('returns null when providerId is missing', () {
      final claimsMap = {'sub': 'test-subject', 'email': 'test@example.com'};

      final claims = AuthClaims.fromMap(claimsMap);

      expect(claims, isNull);
    });

    test('returns null when subject is empty', () {
      final claimsMap = {'sub': '', 'provider_id': 'google.com'};

      final claims = AuthClaims.fromMap(claimsMap);

      expect(claims, isNull);
    });

    test('ignores additional claims not in allowed list', () {
      final claimsMap = {
        'sub': 'test-subject',
        'provider_id': 'google.com',
        'roles': ['ADMIN', 'MEMBER'],
        'custom_field': 'should-be-ignored',
        'phone_number': '+1234567890',
      };

      final claims = AuthClaims.fromMap(claimsMap);

      expect(claims, isNotNull);
      expect(claims!.subject, 'test-subject');
      expect(claims.providerId, 'google.com');
      // Additional fields are not stored
    });

    test('equality works correctly', () {
      const claims1 = AuthClaims(
        subject: 'test',
        providerId: 'google.com',
        email: 'test@example.com',
        emailVerified: true,
      );

      const claims2 = AuthClaims(
        subject: 'test',
        providerId: 'google.com',
        email: 'test@example.com',
        emailVerified: true,
      );

      const claims3 = AuthClaims(
        subject: 'different',
        providerId: 'google.com',
      );

      expect(claims1, claims2);
      expect(claims1, isNot(claims3));
    });

    test('hashCode is consistent', () {
      const claims1 = AuthClaims(subject: 'test', providerId: 'google.com');

      const claims2 = AuthClaims(subject: 'test', providerId: 'google.com');

      expect(claims1.hashCode, claims2.hashCode);
    });

    test('toString contains all information', () {
      const claims = AuthClaims(
        subject: 'test-subject',
        providerId: 'google.com',
        email: 'test@example.com',
        emailVerified: true,
        issuedAt: 123,
        expiresAt: 456,
      );

      final str = claims.toString();

      expect(str, contains('test-subject'));
      expect(str, contains('google.com'));
      expect(str, contains('test@example.com'));
      expect(str, contains('true'));
      expect(str, contains('123'));
      expect(str, contains('456'));
    });
  });
}
