// ignore_for_file: avoid_print

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart' as domain;
import 'package:dartzen_infrastructure_identity/dartzen_infrastructure_identity.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Example implementation of [IdentityPersistencePort] for demonstration.
///
/// In a real application, this would interact with a database or storage backend.
class ExamplePersistencePort implements IdentityPersistencePort {
  final Map<String, domain.IdentityId> _subjectToIdMap = {};
  final Map<String, domain.Identity> _identityStore = {};

  @override
  Future<ZenResult<domain.IdentityId>> resolveIdentityId(
    String externalSubject,
  ) async {
    final id = _subjectToIdMap[externalSubject];
    if (id == null) {
      return const ZenResult.err(ZenValidationError('IDENTITY_NOT_FOUND'));
    }
    return ZenResult.ok(id);
  }

  @override
  Future<ZenResult<domain.Identity>> loadIdentity(domain.IdentityId id) async {
    final identity = _identityStore[id.value];
    if (identity == null) {
      return const ZenResult.err(ZenValidationError('IDENTITY_NOT_FOUND'));
    }
    return ZenResult.ok(identity);
  }

  @override
  Future<ZenResult<domain.Identity>> createIdentity(
    String externalSubject,
    AuthClaims claims,
  ) async {
    // Generate a new identity ID
    final idResult = domain.IdentityId.create(
      'id-${_identityStore.length + 1}',
    );
    if (idResult.isFailure) {
      return ZenResult.err(idResult.errorOrNull!);
    }

    final id = idResult.dataOrNull!;

    // Create domain identity with minimal authority
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
      // Store mapping and identity
      _subjectToIdMap[externalSubject] = id;
      _identityStore[id.value] = identity;
      return ZenResult.ok(identity);
    }, ZenResult.err);
  }
}

void main() async {
  print('=== DartZen Infrastructure Identity Example ===\n');

  // 1. Setup localization
  final localization = ZenLocalizationService(
    config: const ZenLocalizationConfig(
      // ignore: avoid_redundant_argument_values
      isProduction: false,
    ),
  );

  // 2. Create messages instance
  final messages = InfrastructureIdentityMessages(
    localization: localization,
    language: 'en',
  );

  // 3. Create persistence port (in-memory for this example)
  final persistencePort = ExamplePersistencePort();

  // 4. Create identity resolver
  final resolver = IdentityResolver(
    persistencePort: persistencePort,
    messages: messages,
  );

  // === SCENARIO 1: New User Sign-In ===
  print('SCENARIO 1: New user signing in via Google\n');

  final newUserClaims = AuthClaims(
    subject: 'google-uid-abc123',
    providerId: 'google.com',
    email: 'newuser@example.com',
    issuedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    expiresAt:
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  );

  print('Auth claims: $newUserClaims\n');

  final newUserResult = await resolver.resolve(newUserClaims);

  newUserResult.fold(
    (identity) {
      print('✅ Identity created successfully:');

      print('   ID: ${identity.id.value}');

      print('   State: ${identity.lifecycle.state}');

      print(
        '   Roles: ${identity.authority.roles.map((r) => r.name).join(', ')}',
      );
    },
    (error) {
      print('❌ Failed to create identity: $error');
    },
  );

  print('\n${"=" * 50}\n');

  // === SCENARIO 2: Existing User Sign-In ===

  print('SCENARIO 2: Existing user signing in again\n');

  const existingUserClaims = AuthClaims(
    subject: 'google-uid-abc123', // Same subject as before
    providerId: 'google.com',
    email: 'newuser@example.com',
    emailVerified: true,
  );

  final existingUserResult = await resolver.resolve(existingUserClaims);

  existingUserResult.fold(
    (identity) {
      print('✅ Identity loaded successfully:');

      print('   ID: ${identity.id.value}');

      print('   State: ${identity.lifecycle.state}');

      print(
        '   Roles: ${identity.authority.roles.map((r) => r.name).join(', ')}',
      );
    },
    (error) {
      print('❌ Failed to load identity: $error');
    },
  );

  print('\n${"=" * 50}\n');

  // === SCENARIO 3: Parsing Claims from Token ===

  print('SCENARIO 3: Parsing claims from raw token payload\n');

  final rawTokenPayload = {
    'sub': 'firebase-uid-xyz789',
    'firebase': {'sign_in_provider': 'github.com'},
    'email': 'developer@example.com',
    'email_verified': false,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  };

  print('Raw token payload: $rawTokenPayload\n');

  final parsedClaims = AuthClaims.fromMap(rawTokenPayload);

  if (parsedClaims == null) {
    print('❌ Failed to parse claims from token');
  } else {
    print('✅ Claims parsed successfully: $parsedClaims\n');

    final parsedResult = await resolver.resolve(parsedClaims);

    parsedResult.fold(
      (identity) {
        print('✅ Identity created from parsed claims:');

        print('   ID: ${identity.id.value}');

        print('   State: ${identity.lifecycle.state}');
      },
      (error) {
        print('❌ Failed to resolve identity: $error');
      },
    );
  }

  print('\n${"=" * 50}\n');

  print('Example completed successfully!');
}
