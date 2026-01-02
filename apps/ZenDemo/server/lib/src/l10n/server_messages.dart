import 'package:dartzen_localization/dartzen_localization.dart';

/// Server-side localization messages for ZenDemo.
class ServerMessages {
  /// Creates server messages.
  const ServerMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  /// Message for successful ping.
  String pingSuccess() => _localization.translate(
        'zen_demo.ping.success',
        language: _language,
        module: 'zen_demo',
      );

  /// Message for WebSocket connected.
  String websocketConnected() => _localization.translate(
        'zen_demo.websocket.connected',
        language: _language,
        module: 'zen_demo',
      );

  /// Message for WebSocket disconnected.
  String websocketDisconnected() => _localization.translate(
        'zen_demo.websocket.disconnected',
        language: _language,
        module: 'zen_demo',
      );

  /// Message for WebSocket error.
  String websocketError(String error) => _localization.translate(
        'zen_demo.websocket.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );

  /// Message for terms loading.
  String termsLoading() => _localization.translate(
        'zen_demo.terms.loading',
        language: _language,
        module: 'zen_demo',
      );

  /// Message for terms error.
  String termsError(String error) => _localization.translate(
        'zen_demo.terms.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );

  /// Message for profile loading.
  String profileLoading() => _localization.translate(
        'zen_demo.profile.loading',
        language: _language,
        module: 'zen_demo',
      );

  /// Message for profile error.
  String profileError(String error) => _localization.translate(
        'zen_demo.profile.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );
}
