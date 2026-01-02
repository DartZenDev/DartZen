import 'package:dartzen_demo_client/src/l10n/client_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalizationService extends ZenLocalizationService {
  MockLocalizationService() : super(config: const ZenLocalizationConfig());

  @override
  String translate(
    String key, {
    required String language,
    String? module,
    Map<String, dynamic>? params,
  }) {
    // For translateError unknown error test
    if (key == 'dartzen_demo.error.some_random_error_code') {
      return key; // Return key itself to simulate not found
    }
    // Return a predictable string for testing
    if (params != null) {
      return 'translated:$key:${params.values.join(',')}';
    }
    return 'translated:$key';
  }
}

void main() {
  group('ClientMessages', () {
    late MockLocalizationService localization;
    late ClientMessages messages;

    setUp(() {
      localization = MockLocalizationService();
      messages = ClientMessages(localization, 'en');
    });

    test('welcomeTitle calls localization service', () {
      final result = messages.welcomeTitle();
      expect(result, contains('welcome.title'));
    });

    test('welcomeSubtitle calls localization service', () {
      final result = messages.welcomeSubtitle();
      expect(result, contains('welcome.subtitle'));
    });

    test('mainPing calls localization service', () {
      final result = messages.mainPing();
      expect(result, contains('main.ping'));
    });

    test('mainPingSuccess includes message parameter', () {
      final result = messages.mainPingSuccess('pong');
      expect(result, contains('ping_success'));
    });

    test('mainPingError includes error parameter', () {
      final result = messages.mainPingError('timeout');
      expect(result, contains('ping_error'));
    });

    test('mainWebSocketConnect calls localization service', () {
      final result = messages.mainWebSocketConnect();
      expect(result, contains('websocket_connect'));
    });

    test('mainWebSocketDisconnect calls localization service', () {
      final result = messages.mainWebSocketDisconnect();
      expect(result, contains('websocket_disconnect'));
    });

    test('mainWebSocketSend calls localization service', () {
      final result = messages.mainWebSocketSend();
      expect(result, contains('websocket_send'));
    });

    test('mainWebSocketStatus includes status parameter', () {
      final result = messages.mainWebSocketStatus('connected');
      expect(result, contains('websocket_status'));
    });

    test('mainWebSocketReceived includes message parameter', () {
      final result = messages.mainWebSocketReceived('echo');
      expect(result, contains('websocket_received'));
    });

    test('mainLanguage calls localization service', () {
      final result = messages.mainLanguage();
      expect(result, contains('main.language'));
    });

    test('mainViewTerms calls localization service', () {
      final result = messages.mainViewTerms();
      expect(result, contains('view_terms'));
    });

    test('mainViewProfile calls localization service', () {
      final result = messages.mainViewProfile();
      expect(result, contains('view_profile'));
    });

    test('profileTitle calls localization service', () {
      final result = messages.profileTitle();
      expect(result, contains('profile.title'));
    });

    test('profileUserId calls localization service', () {
      final result = messages.profileUserId();
      expect(result, contains('user_id'));
    });

    test('profileEmail calls localization service', () {
      final result = messages.profileEmail();
      expect(result, contains('email'));
    });

    test('profileDisplayName calls localization service', () {
      final result = messages.profileDisplayName();
      expect(result, contains('display_name'));
    });

    test('profileBio calls localization service', () {
      final result = messages.profileBio();
      expect(result, contains('bio'));
    });

    test('profileStatus calls localization service', () {
      final result = messages.profileStatus();
      expect(result, contains('status'));
    });

    test('profileRoles calls localization service', () {
      final result = messages.profileRoles();
      expect(result, contains('roles'));
    });

    test('profileLoading calls localization service', () {
      final result = messages.profileLoading();
      expect(result, contains('loading'));
    });

    test('profileError includes error parameter', () {
      final result = messages.profileError('unauthorized');
      expect(result, contains('error'));
    });

    test('termsTitle calls localization service', () {
      final result = messages.termsTitle();
      expect(result, contains('terms.title'));
    });

    test('termsLoading calls localization service', () {
      final result = messages.termsLoading();
      expect(result, contains('loading'));
    });

    test('termsError includes error parameter', () {
      final result = messages.termsError('not_found');
      expect(result, contains('error'));
    });

    test('translateError returns translation for known error', () {
      final result = messages.translateError('invalid_credentials');
      expect(result, contains('error.invalid_credentials'));
    });

    test('translateError returns unknown error for unknown code', () {
      final result = messages.translateError('some_random_error_code');
      expect(result, contains('error.unknown'));
    });
  });
}
