import 'package:dartzen_localization/dartzen_localization.dart';

/// Message accessor for Identity module.
///
/// Encapsulates all localization keys of the package.
class IdentityMessages {
  final ZenLocalizationService _localization;
  final String _language;

  /// Creates an [IdentityMessages] instance.
  const IdentityMessages(this._localization, this._language);

  /// Message for identity not found.
  String identityNotFound(String id) => _localization.translate(
    'identity.error.not_found',
    language: _language,
    module: 'identity',
    params: {'id': id},
  );

  /// Message for revoked identity error.
  String identityRevoked() => _localization.translate(
    'identity.error.revoked',
    language: _language,
    module: 'identity',
  );

  /// Message for inactive identity error.
  String identityNotActive() => _localization.translate(
    'identity.error.not_active',
    language: _language,
    module: 'identity',
  );

  /// Message for empty identity ID error.
  String emptyId() => _localization.translate(
    'identity.error.empty_id',
    language: _language,
    module: 'identity',
  );

  /// Message for empty revocation reason error.
  String emptyReason() => _localization.translate(
    'identity.error.empty_reason',
    language: _language,
    module: 'identity',
  );
}
