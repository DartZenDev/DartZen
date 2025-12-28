import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:meta/meta.dart';

/// Package-scoped messages for dartzen_infrastructure_identity.
///
/// This class encapsulates all localization keys for this package.
/// Direct calls to [ZenLocalizationService.translate] are FORBIDDEN
/// outside this class.
@immutable
class InfrastructureIdentityMessages {
  static const _module = 'dartzen_infrastructure_identity';

  final ZenLocalizationService _localization;
  final String _language;

  /// Creates an [InfrastructureIdentityMessages] instance.
  ///
  /// The [language] parameter determines which locale to use for messages.
  const InfrastructureIdentityMessages({
    required ZenLocalizationService localization,
    required String language,
  }) : _localization = localization,
       _language = language;

  /// Message: Resolving identity for external subject.
  String resolvingIdentity({
    required String subject,
    required String providerId,
  }) => _localization.translate(
    'resolving_identity',
    language: _language,
    module: _module,
    params: {'subject': subject, 'providerId': providerId},
  );

  /// Message: Identity resolution failed.
  String resolutionFailed({
    required String subject,
    required String providerId,
  }) => _localization.translate(
    'resolution_failed',
    language: _language,
    module: _module,
    params: {'subject': subject, 'providerId': providerId},
  );

  /// Message: Loading existing identity.
  String loadingIdentity({
    required String identityId,
    required String subject,
  }) => _localization.translate(
    'loading_identity',
    language: _language,
    module: _module,
    params: {'identityId': identityId, 'subject': subject},
  );

  /// Message: Identity loaded successfully.
  String identityLoaded({required String identityId}) =>
      _localization.translate(
        'identity_loaded',
        language: _language,
        module: _module,
        params: {'identityId': identityId},
      );

  /// Message: Identity load failed.
  String identityLoadFailed({required String identityId}) =>
      _localization.translate(
        'identity_load_failed',
        language: _language,
        module: _module,
        params: {'identityId': identityId},
      );

  /// Message: Creating new identity.
  String creatingIdentity({
    required String subject,
    required String providerId,
  }) => _localization.translate(
    'creating_identity',
    language: _language,
    module: _module,
    params: {'subject': subject, 'providerId': providerId},
  );

  /// Message: Identity created successfully.
  String identityCreated({required String identityId}) =>
      _localization.translate(
        'identity_created',
        language: _language,
        module: _module,
        params: {'identityId': identityId},
      );

  /// Message: Identity creation failed.
  String identityCreationFailed({required String subject}) =>
      _localization.translate(
        'identity_creation_failed',
        language: _language,
        module: _module,
        params: {'subject': subject},
      );

  /// Message: External identity mapping failed.
  String mappingFailed() => _localization.translate(
    'mapping_failed',
    language: _language,
    module: _module,
  );
}
