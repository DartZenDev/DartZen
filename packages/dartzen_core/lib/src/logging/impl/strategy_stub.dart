import 'strategy.dart';

// ignore_for_file: avoid_print

/// Fallback strategy for basic logging.
class ZenLoggerStrategyStub implements ZenLoggerStrategy {
  @override
  void log(String message, {bool isError = false}) {
    // Fallback: simple print if platform unknown?
    // Or throw? Simple print is safer.
    print(message);
  }
}

/// Returns the Stub logging strategy.
ZenLoggerStrategy getStrategy() => ZenLoggerStrategyStub();
