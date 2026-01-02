import 'package:dartzen_demo_client/src/app_state.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock config for testing
ZenLocalizationConfig _testConfig() => const ZenLocalizationConfig(
  isProduction: false,
  globalPath: 'test/locales',
);

void main() {
  group('AppStateData', () {
    test('creates with default language', () {
      const state = AppStateData();
      expect(state.language, 'en');
      expect(state.userId, isNull);
      expect(state.idToken, isNull);
      expect(state.localization, isNull);
    });

    test('creates with custom values', () {
      final localization = ZenLocalizationService(config: _testConfig());
      final state = AppStateData(
        language: 'pl',
        userId: 'user123',
        idToken: 'token456',
        localization: localization,
      );
      expect(state.language, 'pl');
      expect(state.userId, 'user123');
      expect(state.idToken, 'token456');
      expect(state.localization, localization);
    });

    test('copyWith preserves unmodified fields', () {
      final localization = ZenLocalizationService(config: _testConfig());
      final state = AppStateData(
        userId: 'user123',
        idToken: 'token456',
        localization: localization,
      );

      final copied = state.copyWith();
      expect(copied.language, 'en');
      expect(copied.userId, 'user123');
      expect(copied.idToken, 'token456');
      expect(copied.localization, localization);
    });

    test('copyWith updates language', () {
      const state = AppStateData();
      final copied = state.copyWith(language: 'pl');
      expect(copied.language, 'pl');
    });

    test('copyWith can set userId to null explicitly', () {
      const state = AppStateData(userId: 'user123');
      final copied = state.copyWith(userId: null);
      expect(copied.userId, isNull);
    });

    test('copyWith can set idToken to null explicitly', () {
      const state = AppStateData(idToken: 'token123');
      final copied = state.copyWith(idToken: null);
      expect(copied.idToken, isNull);
    });

    test('copyWith can set both userId and idToken to null', () {
      const state = AppStateData(userId: 'user123', idToken: 'token456');
      final copied = state.copyWith(userId: null, idToken: null);
      expect(copied.userId, isNull);
      expect(copied.idToken, isNull);
    });

    test('copyWith updates localization', () {
      final loc1 = ZenLocalizationService(config: _testConfig());
      final loc2 = ZenLocalizationService(config: _testConfig());
      final state = AppStateData(localization: loc1);
      final copied = state.copyWith(localization: loc2);
      expect(copied.localization, loc2);
    });
  });

  group('AppState', () {
    test('creates with default state', () {
      final appState = AppState();
      expect(appState.language, 'en');
      expect(appState.userId, isNull);
      expect(appState.idToken, isNull);
      expect(appState.localization, isNull);
    });

    test('creates with initial state', () {
      const initial = AppStateData(
        language: 'pl',
        userId: 'user123',
        idToken: 'token456',
      );
      final appState = AppState(initial: initial);
      expect(appState.language, 'pl');
      expect(appState.userId, 'user123');
      expect(appState.idToken, 'token456');
    });

    test('value getter returns current state', () {
      const initial = AppStateData(language: 'pl');
      final appState = AppState(initial: initial);
      expect(appState.value, initial);
    });

    test('setLanguage updates language and notifies listeners', () {
      final appState = AppState();
      var notified = false;
      appState.addListener(() => notified = true);

      appState.setLanguage('pl');

      expect(appState.language, 'pl');
      expect(notified, isTrue);
    });

    test('setUserId updates userId and notifies listeners', () {
      final appState = AppState();
      var notified = false;
      appState.addListener(() => notified = true);

      appState.setUserId('user123');

      expect(appState.userId, 'user123');
      expect(notified, isTrue);
    });

    test('setUserId clears token when logging out', () {
      final appState = AppState(
        initial: const AppStateData(userId: 'user123', idToken: 'token456'),
      );

      appState.setUserId(null);

      expect(appState.userId, isNull);
      expect(appState.idToken, isNull);
    });

    test('setUserId preserves token when setting new userId', () {
      final appState = AppState(
        initial: const AppStateData(idToken: 'token456'),
      );

      appState.setUserId('user123');

      expect(appState.userId, 'user123');
      expect(appState.idToken, 'token456');
    });

    test('setIdToken updates token and notifies listeners', () {
      final appState = AppState();
      var notified = false;
      appState.addListener(() => notified = true);

      appState.setIdToken('token123');

      expect(appState.idToken, 'token123');
      expect(notified, isTrue);
    });

    test('setIdToken can clear token', () {
      final appState = AppState(
        initial: const AppStateData(idToken: 'token123'),
      );

      appState.setIdToken(null);

      expect(appState.idToken, isNull);
    });

    test('setLocalization updates localization and notifies listeners', () {
      final appState = AppState();
      final localization = ZenLocalizationService(config: _testConfig());
      var notified = false;
      appState.addListener(() => notified = true);

      appState.setLocalization(localization);

      expect(appState.localization, localization);
      expect(notified, isTrue);
    });

    test('multiple state changes notify listeners correctly', () {
      final appState = AppState();
      var notifyCount = 0;
      appState.addListener(() => notifyCount++);

      appState.setLanguage('pl');
      appState.setUserId('user123');
      appState.setIdToken('token456');

      expect(notifyCount, 3);
      expect(appState.language, 'pl');
      expect(appState.userId, 'user123');
      expect(appState.idToken, 'token456');
    });
  });
}
