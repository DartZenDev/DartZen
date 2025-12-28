import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart' as domain;
import 'package:meta/meta.dart';

import 'auth_claims.dart';
import 'l10n/infrastructure_identity_messages.dart';

/// Port for persistence operations required by the identity resolver.
///
/// This adapter delegates all persistence to an external implementation.
/// It does NOT persist data directly.
abstract interface class IdentityPersistencePort {
  /// Resolves a domain identity ID from an external subject reference.
  ///
  /// Returns [ZenResult.ok] with the identity ID if mapping exists.
  /// Returns [ZenResult.err] if no mapping exists.
  Future<ZenResult<domain.IdentityId>> resolveIdentityId(
    String externalSubject,
  );

  /// Loads a domain identity by its ID.
  ///
  /// Returns [ZenResult.ok] with the identity if found.
  /// Returns [ZenResult.err] if not found.
  Future<ZenResult<domain.Identity>> loadIdentity(domain.IdentityId id);

  /// Requests domain-level identity creation.
  ///
  /// This method does NOT decide whether creation is allowed.
  /// That decision belongs to the domain layer.
  ///
  /// Returns [ZenResult.ok] with the created identity if successful.
  /// Returns [ZenResult.err] if creation fails or is not allowed.
  Future<ZenResult<domain.Identity>> createIdentity(
    String externalSubject,
    AuthClaims claims,
  );
}

/// Pure infrastructure adapter that bridges external authentication systems
/// with the DartZen Identity domain.
///
/// This adapter answers exactly one question:
/// "Given a verified external authentication result, how does it map to a domain Identity?"
///
/// ## Responsibilities
///
/// - Receive verified auth claims
/// - Resolve external reference → domain identity (via persistence port)
/// - Load or request creation of domain identity
/// - Return result wrapped in [ZenResult]
///
/// ## Explicit Non-Responsibilities
///
/// - Token verification (happens outside this package)
/// - Credential validation
/// - Role inference
/// - Permission checks
/// - Lifecycle transitions
/// - Default identity creation
/// - Direct persistence
///
/// All behavior is explicit and mechanically traceable.
@immutable
class IdentityResolver {
  final IdentityPersistencePort _persistencePort;
  final InfrastructureIdentityMessages _messages;

  /// Creates an [IdentityResolver].
  ///
  /// Requires a [persistencePort] for all storage operations and
  /// a [messages] instance for localized error messages.
  const IdentityResolver({
    required IdentityPersistencePort persistencePort,
    required InfrastructureIdentityMessages messages,
  }) : _persistencePort = persistencePort,
       _messages = messages;

  /// Resolves verified authentication claims to a domain identity.
  ///
  /// ## Flow
  ///
  /// 1. Receive verified [claims]
  /// 2. Resolve external subject → domain identity ID
  /// 3. If identity exists: load domain identity
  /// 4. If identity does not exist: request domain-level identity creation
  /// 5. Return result wrapped in [ZenResult]
  ///
  /// ## Error Handling
  ///
  /// All errors are mapped to identity contract errors and wrapped in [ZenResult].
  /// No raw SDK or platform exceptions escape this method.
  ///
  /// Auth failures are NOT identity failures unless explicitly defined by the contract.
  Future<ZenResult<domain.Identity>> resolve(AuthClaims claims) async {
    ZenLogger.instance.info(
      _messages.resolvingIdentity(
        subject: _hashSubject(claims.subject),
        providerId: claims.providerId,
      ),
    );

    try {
      // Step 1: Resolve external subject to domain identity ID
      final idResult = await _persistencePort.resolveIdentityId(claims.subject);

      return idResult.fold(
        (identityId) => _loadExistingIdentity(identityId, claims),
        (_) => _createNewIdentity(claims),
      );
    } catch (e, stackTrace) {
      ZenLogger.instance.error(
        _messages.resolutionFailed(
          subject: _hashSubject(claims.subject),
          providerId: claims.providerId,
        ),
        error: e,
        stackTrace: stackTrace,
      );

      return ZenResult.err(ZenValidationError(_messages.mappingFailed()));
    }
  }

  /// Loads an existing identity from persistence.
  Future<ZenResult<domain.Identity>> _loadExistingIdentity(
    domain.IdentityId id,
    AuthClaims claims,
  ) async {
    ZenLogger.instance.info(
      _messages.loadingIdentity(
        identityId: id.value,
        subject: _hashSubject(claims.subject),
      ),
    );

    final loadResult = await _persistencePort.loadIdentity(id);

    return loadResult.fold(
      (identity) {
        ZenLogger.instance.info(_messages.identityLoaded(identityId: id.value));
        return ZenResult.ok(identity);
      },
      (error) {
        ZenLogger.instance.warn(
          _messages.identityLoadFailed(identityId: id.value),
        );
        return ZenResult.err(error);
      },
    );
  }

  /// Requests domain-level identity creation.
  Future<ZenResult<domain.Identity>> _createNewIdentity(
    AuthClaims claims,
  ) async {
    ZenLogger.instance.info(
      _messages.creatingIdentity(
        subject: _hashSubject(claims.subject),
        providerId: claims.providerId,
      ),
    );

    final createResult = await _persistencePort.createIdentity(
      claims.subject,
      claims,
    );

    return createResult.fold(
      (identity) {
        ZenLogger.instance.info(
          _messages.identityCreated(identityId: identity.id.value),
        );
        return ZenResult.ok(identity);
      },
      (error) {
        ZenLogger.instance.warn(
          _messages.identityCreationFailed(
            subject: _hashSubject(claims.subject),
          ),
        );
        return ZenResult.err(error);
      },
    );
  }

  /// Hashes or redacts the subject for logging.
  ///
  /// Never logs raw subject identifiers or PII.
  String _hashSubject(String subject) {
    if (subject.length <= 8) return '***';
    return '${subject.substring(0, 4)}...${subject.substring(subject.length - 4)}';
  }
}
