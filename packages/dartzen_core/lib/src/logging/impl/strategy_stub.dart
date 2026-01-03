import 'strategy.dart';

// ignore_for_file: avoid_print

/// Fallback strategy for basic logging.
class ZenLoggerStrategyStub implements ZenLoggerStrategy {
  @override
  void log(String message, {bool isError = false, String? origin}) {
    final out = origin != null ? '[$origin] $message' : message;
    print(out);
  }
}

/// Returns the Stub logging strategy.
ZenLoggerStrategy getStrategy() => ZenLoggerStrategyStub();
