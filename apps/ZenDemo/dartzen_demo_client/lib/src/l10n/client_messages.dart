import 'package:dartzen_localization/dartzen_localization.dart';

/// Client-side localization messages for ZenDemo.
class ClientMessages {
  /// Creates client messages.
  const ClientMessages(this._localization, this._language);

  final ZenLocalizationService _localization;
  final String _language;

  /// Returns the welcome screen title.
  String welcomeTitle() => _localization.translate(
    'dartzen_demo.welcome.title',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the welcome screen subtitle.
  String welcomeSubtitle() => _localization.translate(
    'dartzen_demo.welcome.subtitle',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the ping button label.
  String mainPing() => _localization.translate(
    'dartzen_demo.main.ping',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the ping success message.
  String mainPingSuccess(String message) => _localization.translate(
    'dartzen_demo.main.ping_success',
    language: _language,
    module: 'dartzen_demo',
    params: {'message': message},
  );

  /// Returns the ping error message.
  String mainPingError(String error) => _localization.translate(
    'dartzen_demo.main.ping_error',
    language: _language,
    module: 'dartzen_demo',
    params: {'error': error},
  );

  /// Returns the WebSocket connect button label.
  String mainWebSocketConnect() => _localization.translate(
    'dartzen_demo.main.websocket_connect',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the WebSocket disconnect button label.
  String mainWebSocketDisconnect() => _localization.translate(
    'dartzen_demo.main.websocket_disconnect',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the WebSocket send button label.
  String mainWebSocketSend() => _localization.translate(
    'dartzen_demo.main.websocket_send',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the WebSocket status message.
  String mainWebSocketStatus(String status) => _localization.translate(
    'dartzen_demo.main.websocket_status',
    language: _language,
    module: 'dartzen_demo',
    params: {'status': status},
  );

  /// Returns the WebSocket received message.
  String mainWebSocketReceived(String message) => _localization.translate(
    'dartzen_demo.main.websocket_received',
    language: _language,
    module: 'dartzen_demo',
    params: {'message': message},
  );

  /// Returns the language selector label.
  String mainLanguage() => _localization.translate(
    'dartzen_demo.main.language',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the view terms button label.
  String mainViewTerms() => _localization.translate(
    'dartzen_demo.main.view_terms',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the view profile button label.
  String mainViewProfile() => _localization.translate(
    'dartzen_demo.main.view_profile',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the profile screen title.
  String profileTitle() => _localization.translate(
    'dartzen_demo.profile.title',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the user ID label.
  String profileUserId() => _localization.translate(
    'dartzen_demo.profile.user_id',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the display name label.
  String profileDisplayName() => _localization.translate(
    'dartzen_demo.profile.display_name',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the email label.
  String profileEmail() => _localization.translate(
    'dartzen_demo.profile.email',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the bio label.
  String profileBio() => _localization.translate(
    'dartzen_demo.profile.bio',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the status label.
  String profileStatus() => _localization.translate(
    'dartzen_demo.profile.status',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the roles label.
  String profileRoles() => _localization.translate(
    'dartzen_demo.profile.roles',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the profile loading message.
  String profileLoading() => _localization.translate(
    'dartzen_demo.profile.loading',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the profile error message.
  String profileError(String error) => _localization.translate(
    'dartzen_demo.profile.error',
    language: _language,
    module: 'dartzen_demo',
    params: {'error': error},
  );

  /// Returns the terms screen title.
  String termsTitle() => _localization.translate(
    'dartzen_demo.terms.title',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the terms loading message.
  String termsLoading() => _localization.translate(
    'dartzen_demo.terms.loading',
    language: _language,
    module: 'dartzen_demo',
  );

  /// Returns the terms error message.
  String termsError(String error) => _localization.translate(
    'dartzen_demo.terms.error',
    language: _language,
    module: 'dartzen_demo',
    params: {'error': error},
  );

  /// Translates an error code to a localized message.
  ///
  /// If the error code is not found, returns the error code itself.
  String translateError(String errorCode) {
    final key = 'dartzen_demo.error.$errorCode';
    final translation = _localization.translate(
      key,
      language: _language,
      module: 'dartzen_demo',
    );

    // If translation returns the key itself (not found), use unknown error
    if (translation == key) {
      return _localization.translate(
        'dartzen_demo.error.unknown',
        language: _language,
        module: 'dartzen_demo',
      );
    }

    return translation;
  }
}
