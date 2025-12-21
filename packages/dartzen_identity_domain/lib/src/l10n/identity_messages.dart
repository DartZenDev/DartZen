import 'package:dartzen_localization/dartzen_localization.dart';

/// Typed messages accessor for the 'identity' module.
class IdentityMessages {
  /// Creates an [IdentityMessages] wrapper.
  const IdentityMessages(this._service, this._language);

  final ZenLocalizationService _service;
  final String _language;

  /// Error message when identity is revoked.
  String get errorRevoked => _t('identity.error.revoked');

  /// Error message when identity is inactive.
  String get errorInactive => _t('identity.error.inactive');

  /// Error message when permission is denied.
  String get errorInsufficientPermissions =>
      _t('identity.error.insufficient_permissions');

  /// Helper to reduce boilerplate.
  String _t(String key) =>
      _service.translate(key, language: _language, module: 'identity');
}
