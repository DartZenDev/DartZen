import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter/material.dart';

/// Immutable snapshot of the application state.
@immutable
class AppStateData {
  /// Creates a new state snapshot.
  const AppStateData({
    this.language = 'en',
    this.userId,
    this.idToken,
    this.localization,
  });

  /// Current language code.
  final String language;

  /// Authenticated user ID (if any).
  final String? userId;

  /// Firebase ID token for API calls.
  final String? idToken;

  /// Localization service instance.
  final ZenLocalizationService? localization;

  /// Returns a copy with overridden fields.
  AppStateData copyWith({
    String? language,
    String? userId,
    String? idToken,
    ZenLocalizationService? localization,
  }) =>
      AppStateData(
        language: language ?? this.language,
        userId: userId ?? this.userId,
        idToken: idToken ?? this.idToken,
        localization: localization ?? this.localization,
      );
}

/// Notifies listeners about immutable [AppStateData] changes.
class AppState extends ChangeNotifier {
  /// Creates an [AppState] with optional initial data.
  AppState({AppStateData? initial}) : _data = initial ?? const AppStateData();

  AppStateData _data;

  /// Current state snapshot.
  AppStateData get value => _data;

  /// Current language code.
  String get language => _data.language;

  /// Current authenticated user ID, if any.
  String? get userId => _data.userId;

  /// Current ID token for API calls.
  String? get idToken => _data.idToken;

  /// Current localization service.
  ZenLocalizationService? get localization => _data.localization;

  /// Updates localization service reference.
  void setLocalization(ZenLocalizationService service) {
    _data = _data.copyWith(localization: service);
    notifyListeners();
  }

  /// Changes the current language.
  void setLanguage(String language) {
    _data = _data.copyWith(language: language);
    notifyListeners();
  }

  /// Sets user id and clears token when logging out.
  void setUserId(String? userId) {
    _data = _data.copyWith(
      userId: userId,
      idToken: userId == null ? null : _data.idToken,
    );
    notifyListeners();
  }

  /// Updates the ID token for authenticated requests.
  void setIdToken(String? token) {
    _data = _data.copyWith(idToken: token);
    notifyListeners();
  }
}
