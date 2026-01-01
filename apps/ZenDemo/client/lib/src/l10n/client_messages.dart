import 'package:dartzen_localization/dartzen_localization.dart';

/// Client-side localization messages for ZenDemo.
class ClientMessages {
  /// Creates client messages.
  const ClientMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  /// Returns the welcome screen title.
  String welcomeTitle() => _localization.translate(
        'zen_demo.welcome.title',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the welcome screen subtitle.
  String welcomeSubtitle() => _localization.translate(
        'zen_demo.welcome.subtitle',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the ping button label.
  String mainPing() => _localization.translate(
        'zen_demo.main.ping',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the ping success message.
  String mainPingSuccess(String message) => _localization.translate(
        'zen_demo.main.ping_success',
        language: _language,
        module: 'zen_demo',
        params: {'message': message},
      );

  /// Returns the ping error message.
  String mainPingError(String error) => _localization.translate(
        'zen_demo.main.ping_error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );

  /// Returns the WebSocket connect button label.
  String mainWebSocketConnect() => _localization.translate(
        'zen_demo.main.websocket_connect',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the WebSocket disconnect button label.
  String mainWebSocketDisconnect() => _localization.translate(
        'zen_demo.main.websocket_disconnect',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the WebSocket send button label.
  String mainWebSocketSend() => _localization.translate(
        'zen_demo.main.websocket_send',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the WebSocket status message.
  String mainWebSocketStatus(String status) => _localization.translate(
        'zen_demo.main.websocket_status',
        language: _language,
        module: 'zen_demo',
        params: {'status': status},
      );

  /// Returns the WebSocket received message.
  String mainWebSocketReceived(String message) => _localization.translate(
        'zen_demo.main.websocket_received',
        language: _language,
        module: 'zen_demo',
        params: {'message': message},
      );

  /// Returns the language selector label.
  String mainLanguage() => _localization.translate(
        'zen_demo.main.language',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the view terms button label.
  String mainViewTerms() => _localization.translate(
        'zen_demo.main.view_terms',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the view profile button label.
  String mainViewProfile() => _localization.translate(
        'zen_demo.main.view_profile',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the profile screen title.
  String profileTitle() => _localization.translate(
        'zen_demo.profile.title',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the user ID label.
  String profileUserId() => _localization.translate(
        'zen_demo.profile.user_id',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the display name label.
  String profileDisplayName() => _localization.translate(
        'zen_demo.profile.display_name',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the email label.
  String profileEmail() => _localization.translate(
        'zen_demo.profile.email',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the bio label.
  String profileBio() => _localization.translate(
        'zen_demo.profile.bio',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the status label.
  String profileStatus() => _localization.translate(
        'zen_demo.profile.status',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the roles label.
  String profileRoles() => _localization.translate(
        'zen_demo.profile.roles',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the profile loading message.
  String profileLoading() => _localization.translate(
        'zen_demo.profile.loading',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the profile error message.
  String profileError(String error) => _localization.translate(
        'zen_demo.profile.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );

  /// Returns the terms screen title.
  String termsTitle() => _localization.translate(
        'zen_demo.terms.title',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the terms loading message.
  String termsLoading() => _localization.translate(
        'zen_demo.terms.loading',
        language: _language,
        module: 'zen_demo',
      );

  /// Returns the terms error message.
  String termsError(String error) => _localization.translate(
        'zen_demo.terms.error',
        language: _language,
        module: 'zen_demo',
        params: {'error': error},
      );
}
