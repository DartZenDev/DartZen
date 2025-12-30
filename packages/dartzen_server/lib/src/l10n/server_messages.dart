import 'package:dartzen_localization/dartzen_localization.dart';

/// Message accessor for Server module.
///
/// Encapsulates all localization keys of the `dartzen_server` package.
/// Direct calls to [ZenLocalizationService] are forbidden outside this class.
///
/// Translation file: `lib/src/l10n/server.en.json`
class ServerMessages {
  /// Creates a [ServerMessages] instance.
  const ServerMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  /// Message for a healthy server status.
  String healthOk() => _localization.translate(
    'server.health.ok',
    language: _language,
    module: 'server',
  );

  /// Generic error message for unknown server failures.
  String errorUnknown() => _localization.translate(
    'server.error.unknown',
    language: _language,
    module: 'server',
  );

  /// Error message for resource not found.
  String errorNotFound() => _localization.translate(
    'server.error.not_found',
    language: _language,
    module: 'server',
  );
}
