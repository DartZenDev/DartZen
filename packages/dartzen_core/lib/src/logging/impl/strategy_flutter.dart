import 'package:flutter/foundation.dart';

import 'strategy.dart';

/// Strategy for logging in Flutter environments.
class ZenLoggerStrategyFlutter implements ZenLoggerStrategy {
  @override
  void log(String message, {bool isError = false}) {
    // debugPrint creates clean logs in Flutter consoles and handles Android truncation.
    debugPrint(message);
  }
}

/// Returns the Flutter logging strategy.
ZenLoggerStrategy getStrategy() => ZenLoggerStrategyFlutter();
