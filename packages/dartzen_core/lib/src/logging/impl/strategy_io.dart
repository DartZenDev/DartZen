import 'dart:io';

import 'strategy.dart';

/// Strategy for logging in IO environments (Server/CLI).
class ZenLoggerStrategyIO implements ZenLoggerStrategy {
  @override
  void log(String message, {bool isError = false}) {
    if (isError) {
      stderr.writeln(message);
    } else {
      stdout.writeln(message);
    }
  }
}

/// Returns the IO logging strategy.
ZenLoggerStrategy getStrategy() => ZenLoggerStrategyIO();
