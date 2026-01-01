import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter/material.dart';

/// Application state notifier.
class AppState extends ChangeNotifier {
  String _language = 'en';
  String? _userId;
  ZenLocalizationService? _localization;

  String get language => _language;
  String? get userId => _userId;
  ZenLocalizationService? get localization => _localization;

  void setLocalization(ZenLocalizationService service) {
    _localization = service;
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  void setUserId(String? userId) {
    _userId = userId;
    notifyListeners();
  }
}
