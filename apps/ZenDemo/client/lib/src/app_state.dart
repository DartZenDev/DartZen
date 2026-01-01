import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter/material.dart';

/// Application state notifier.
class AppState extends ChangeNotifier {
  String _language = 'en';
  String? _userId;
  ZenLocalizationService? _localization;

  /// The current language code.
  String get language => _language;
  
  /// The current user ID, if authenticated.
  String? get userId => _userId;
  
  /// The localization service instance.
  ZenLocalizationService? get localization => _localization;

  /// Sets the localization service instance.
  void setLocalization(ZenLocalizationService service) {
    _localization = service;
    notifyListeners();
  }

  /// Sets the current language and notifies listeners.
  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  /// Sets the current user ID and notifies listeners.
  void setUserId(String? userId) {
    _userId = userId;
    notifyListeners();
  }
}
