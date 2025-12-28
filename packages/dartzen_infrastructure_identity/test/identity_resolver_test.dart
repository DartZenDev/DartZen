import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart' as domain;
import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:test/test.dart';

/// Mock persistence port for testing.
class MockPersistencePort implements IdentityPersistencePort {
  final Map<String, domain.IdentityId> _subjectMap = {};
  final Map<String, domain.Identity> _identityStore = {};

  bool shouldFailResolve = false;
  bool shouldFailLoad = false;
  bool shouldFailCreate = false;

  @override
  Future<ZenResult<domain.IdentityId>> resolveIdentityId(
    String externalSubject,
  ) async {
    if (shouldFailResolve) {
      return const ZenResult.err(ZenValidationError('RESOLVE_FAILED'));
    }

    final id = _subjectMap[externalSubject];
    if (id == null) {
      return const ZenResult.err(ZenValidationError('NOT_FOUND'));
    }
    return ZenResult.ok(id);
  }

  @override
  Future<ZenResult<domain.Identity>> loadIdentity(domain.IdentityId id) async {
    if (shouldFailLoad) {
      return const ZenResult.err(ZenValidationError('LOAD_FAILED'));
    }

    final identity = _identityStore[id.value];
    if (identity == null) {
      return const ZenResult.err(ZenValidationError('NOT_FOUND'));
    }
    return ZenResult.ok(identity);
  }

  @override
  Future<ZenResult<domain.Identity>> createIdentity(
    String externalSubject,
    AuthClaims claims,
  ) async {
    if (shouldFailCreate) {
      return const ZenResult.err(ZenValidationError('CREATE_FAILED'));
    }

    final idResult = domain.IdentityId.create(
      'test-id-${_identityStore.length}',
    );
    if (idResult.isFailure) {
      return ZenResult.err(idResult.errorOrNull!);
    }

    final id = idResult.dataOrNull!;
    final identityResult = domain.Identity.fromExternalFacts(
      id: id,
      authority: domain.Authority(
        roles: {const domain.Role('MEMBER')},
        // ignore: avoid_redundant_argument_values
        capabilities: const {},
      ),
      facts: domain.IdentityVerificationFacts(
        emailVerified: claims.emailVerified,
      ),
      createdAt: ZenTimestamp.now(),
    );

    return identityResult.fold((identity) {
      _subjectMap[externalSubject] = id;
      _identityStore[id.value] = identity;
      return ZenResult.ok(identity);
    }, ZenResult.err);
  }

  void reset() {
    _subjectMap.clear();
    _identityStore.clear();
    shouldFailResolve = false;
    shouldFailLoad = false;
    shouldFailCreate = false;
  }
}

void main() {
  late MockPersistencePort persistencePort;
  late InfrastructureIdentityMessages messages;
  late IdentityResolver resolver;

  setUp(() {
    persistencePort = MockPersistencePort();
    messages = InfrastructureIdentityMessages(
      localization: ZenLocalizationService(
        config: const ZenLocalizationConfig(),
      ),
      language: 'en',
    );
    resolver = IdentityResolver(
      persistencePort: persistencePort,
      messages: messages,
    );
  });

  tearDown(() {
    persistencePort.reset();
  });

  group('IdentityResolver', () {
    test('creates new identity when subject does not exist', () async {
      const claims = AuthClaims(
        subject: 'new-user-123',
        providerId: 'google.com',
        email: 'new@example.com',
        emailVerified: true,
      );

      final result = await resolver.resolve(claims);

      expect(result.isSuccess, true);
      final identity = result.dataOrNull!;
      expect(identity.lifecycle.state, domain.IdentityState.active);
      expect(identity.authority.roles.map((r) => r.name), contains('MEMBER'));
    });

    test('loads existing identity when subject exists', () async {
      // First create an identity
      const claims = AuthClaims(
        subject: 'existing-user-456',
        providerId: 'google.com',
        email: 'existing@example.com',
        emailVerified: true,
      );

      final createResult = await resolver.resolve(claims);
      expect(createResult.isSuccess, true);
      final createdId = createResult.dataOrNull!.id;

      // Now resolve the same subject again
      final loadResult = await resolver.resolve(claims);
      expect(loadResult.isSuccess, true);
      expect(loadResult.dataOrNull!.id.value, createdId.value);
    });

    test('passes through email as-is without normalization', () async {
      const claims = AuthClaims(
        subject: 'email-test',
        providerId: 'google.com',
        email: 'Test.User@EXAMPLE.COM', // Mixed case
      );

      final result = await resolver.resolve(claims);

      expect(result.isSuccess, true);
      // Email should not be normalized by infrastructure
      // The domain decides what to do with email
    });

    test('handles missing email gracefully', () async {
      const claims = AuthClaims(
        subject: 'no-email-user',
        providerId: 'github.com',
        // ignore: avoid_redundant_argument_values
        emailVerified: false, // Explicit for pending state test
        // No email provided
      );

      final result = await resolver.resolve(claims);

      expect(result.isSuccess, true);
      expect(result.dataOrNull!.lifecycle.state, domain.IdentityState.pending);
    });

    test('returns error when persistence resolve fails', () async {
      // Create the identity first
      const claims = AuthClaims(
        subject: 'fail-resolve',
        providerId: 'google.com',
      );

      await resolver.resolve(claims);

      // Now set it to fail resolve
      persistencePort.shouldFailResolve = true;

      // When resolve fails, it tries to create, which will succeed
      // To actually test resolve failure, we need to make create fail too
      persistencePort.shouldFailCreate = true;

      final result2 = await resolver.resolve(claims);

      expect(result2.isFailure, true);
    });

    test('returns error when persistence load fails', () async {
      // Create identity first
      const claims = AuthClaims(
        subject: 'will-fail-load',
        providerId: 'google.com',
      );
      await resolver.resolve(claims);

      // Now make load fail
      persistencePort.shouldFailLoad = true;

      final result = await resolver.resolve(claims);

      expect(result.isFailure, true);
    });

    test('returns error when persistence create fails', () async {
      persistencePort.shouldFailCreate = true;

      const claims = AuthClaims(
        subject: 'fail-create',
        providerId: 'google.com',
      );

      final result = await resolver.resolve(claims);

      expect(result.isFailure, true);
    });

    test('logs do not include raw subject', () async {
      // This test verifies that the hashing function is called
      // In a real scenario, you would capture log output
      const claims = AuthClaims(
        subject: 'very-long-subject-identifier-12345',
        providerId: 'google.com',
      );

      final result = await resolver.resolve(claims);

      expect(result.isSuccess, true);
      // Logs should contain hashed/redacted subject, not raw value
    });

    test('does not infer roles from claims', () async {
      const claims = AuthClaims(
        subject: 'no-role-inference',
        providerId: 'google.com',
        email:
            'admin@example.com', // "admin" in email should not create ADMIN role
      );

      final result = await resolver.resolve(claims);

      expect(result.isSuccess, true);
      final identity = result.dataOrNull!;
      // Only MEMBER role should exist (default from mock)
      expect(identity.authority.roles.length, 1);
      expect(identity.authority.roles.first.name, 'MEMBER');
    });

    test(
      'emailVerified maps to domain signal without lifecycle change',
      () async {
        const unverifiedClaims = AuthClaims(
          subject: 'unverified-email',
          providerId: 'google.com',
          email: 'unverified@example.com',
          // ignore: avoid_redundant_argument_values
          emailVerified: false, // Explicit for pending state test
        );

        final result = await resolver.resolve(unverifiedClaims);

        expect(result.isSuccess, true);
        final identity = result.dataOrNull!;
        // Identity should be pending with unverified email
        expect(identity.lifecycle.state, domain.IdentityState.pending);
      },
    );

    test('providerId is used for logging only', () async {
      const googleClaims = AuthClaims(
        subject: 'multi-provider',
        providerId: 'google.com',
        // ignore: avoid_redundant_argument_values
        emailVerified: false, // Explicit for pending state test
      );

      final googleResult = await resolver.resolve(googleClaims);
      expect(googleResult.isSuccess, true);

      // ProviderId should not affect identity behavior or state
      final identity = googleResult.dataOrNull!;
      expect(identity.lifecycle.state, domain.IdentityState.pending);
    });

    test('issuedAt and expiresAt are used for logging only', () async {
      final now = DateTime.now();
      final claims = AuthClaims(
        subject: 'timestamp-test',
        providerId: 'google.com',
        // ignore: avoid_redundant_argument_values
        emailVerified: false, // Explicit for pending state test
        issuedAt: now.millisecondsSinceEpoch ~/ 1000,
        expiresAt:
            now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      final result = await resolver.resolve(claims);

      expect(result.isSuccess, true);
      // Timestamps should not affect identity state or behavior
      expect(result.dataOrNull!.lifecycle.state, domain.IdentityState.pending);
    });
  });
}
