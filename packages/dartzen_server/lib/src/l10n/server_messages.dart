import 'package:dartzen_localization/dartzen_localization.dart';

/// Typed messages accessor for the 'server' module.
///
/// This class encapsulates all localization keys used by the `dartzen_server` package.
/// Direct calls to [ZenLocalizationService] are forbidden outside this class.
class ServerMessages {
  /// Creates a [ServerMessages] wrapper.
  const ServerMessages(this._service, this._language);

  final ZenLocalizationService _service;
  final String _language;

  /// Message for a healthy server status.
  String get healthOk => _t('server.health.ok');

  /// Generic error message for unknown server failures.
  String get errorUnknown => _t('server.error.unknown');

  /// Error message for resource not found.
  String get errorNotFound => _t('server.error.not_found');

  /// Title for the Terms & Conditions page.
  String get termsTitle => _t('server.static.terms_title');

  /// Helper to reduce boilerplate.
  String _t(String key) =>
      _service.translate(key, language: _language, module: 'server');
}
