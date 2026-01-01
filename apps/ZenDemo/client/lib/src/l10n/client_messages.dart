import 'package:dartzen_localization/dartzen_localization.dart';

/// Client-side localization messages for ZenDemo.
class ClientMessages {
  /// Creates client messages.
  const ClientMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  String welcomeTitle() => _localization.translate(
        'zen_demo.welcome.title',
        language: _language,
        module: 'zen_demo',
      );

  String welcomeSubtitle() => _localization.translate(
        'zen_demo.welcome.subtitle',
        language: _language,
        module: 'zen_demo',
      );

  String mainPing() => _localization.translate(
        'zen_demo.main.ping',
        language: _language,
        module: 'zen_demo',
      );

  String mainPingSuccess(String message) => _localization.translate(
        'zen_demo.main.ping_success',
        language: _language,
        module: 'zen_demo',
        params: {'message': message},
      );

  String mainPingError(String error) => _localization.translate(
        'zen_demo.main.ping_error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );

  String mainWebSocketConnect() => _localization.translate(
        'zen_demo.main.websocket_connect',
        language: _language,
        module: 'zen_demo',
      );

  String mainWebSocketDisconnect() => _localization.translate(
        'zen_demo.main.websocket_disconnect',
        language: _language,
        module: 'zen_demo',
      );

  String mainWebSocketSend() => _localization.translate(
        'zen_demo.main.websocket_send',
        language: _language,
        module: 'zen_demo',
      );

  String mainWebSocketStatus(String status) => _localization.translate(
        'zen_demo.main.websocket_status',
        language: _language,
        module: 'zen_demo',
        params: {'status': status},
      );

  String mainWebSocketReceived(String message) => _localization.translate(
        'zen_demo.main.websocket_received',
        language: _language,
        module: 'zen_demo',
        params: {'message': message},
      );

  String mainLanguage() => _localization.translate(
        'zen_demo.main.language',
        language: _language,
        module: 'zen_demo',
      );

  String mainViewTerms() => _localization.translate(
        'zen_demo.main.view_terms',
        language: _language,
        module: 'zen_demo',
      );

  String mainViewProfile() => _localization.translate(
        'zen_demo.main.view_profile',
        language: _language,
        module: 'zen_demo',
      );

  String profileTitle() => _localization.translate(
        'zen_demo.profile.title',
        language: _language,
        module: 'zen_demo',
      );

  String profileUserId() => _localization.translate(
        'zen_demo.profile.user_id',
        language: _language,
        module: 'zen_demo',
      );

  String profileDisplayName() => _localization.translate(
        'zen_demo.profile.display_name',
        language: _language,
        module: 'zen_demo',
      );

  String profileEmail() => _localization.translate(
        'zen_demo.profile.email',
        language: _language,
        module: 'zen_demo',
      );

  String profileBio() => _localization.translate(
        'zen_demo.profile.bio',
        language: _language,
        module: 'zen_demo',
      );

  String profileStatus() => _localization.translate(
        'zen_demo.profile.status',
        language: _language,
        module: 'zen_demo',
      );

  String profileRoles() => _localization.translate(
        'zen_demo.profile.roles',
        language: _language,
        module: 'zen_demo',
      );

  String profileLoading() => _localization.translate(
        'zen_demo.profile.loading',
        language: _language,
        module: 'zen_demo',
      );

  String profileError(String error) => _localization.translate(
        'zen_demo.profile.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );

  String termsTitle() => _localization.translate(
        'zen_demo.terms.title',
        language: _language,
        module: 'zen_demo',
      );

  String termsLoading() => _localization.translate(
        'zen_demo.terms.loading',
        language: _language,
        module: 'zen_demo',
      );

  String termsError(String error) => _localization.translate(
        'zen_demo.terms.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );
}
