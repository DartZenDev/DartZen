import 'package:dartzen_localization/dartzen_localization.dart';

/// Server-side localization messages for ZenDemo.
class ServerMessages {
  /// Creates server messages.
  const ServerMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  /// Message for successful ping.
  String pingSuccess() => _localization.translate(
    'dartzen_demo.ping.success',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Message for WebSocket connected.
  String websocketConnected() => _localization.translate(
    'dartzen_demo.websocket.connected',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Message for WebSocket disconnected.
  String websocketDisconnected() => _localization.translate(
    'dartzen_demo.websocket.disconnected',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Message for WebSocket error.
  String websocketError(String error) => _localization.translate(
    'dartzen_demo.websocket.error',
    language: _language,
    module: 'dartzen_demo',
    params: {'error': error},
  );

  /// Message for terms loading.
  String termsLoading() => _localization.translate(
    'dartzen_demo.terms.loading',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Message for terms error.
  String termsError(String error) => _localization.translate(
    'dartzen_demo.terms.error',
    language: _language,
    module: 'dartzen_demo',
    params: {'error': error},
  );

  /// Message for profile loading.
  String profileLoading() => _localization.translate(
    'dartzen_demo.profile.loading',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Message for profile error.
  String profileError(String error) => _localization.translate(
    'dartzen_demo.profile.error',
    language: _language,
    module: 'dartzen_demo',
    params: {'error': error},
  );
}
