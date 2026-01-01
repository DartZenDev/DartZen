import '../zen_logger.dart';
import 'strategy.dart';

/// Strategy for logging in Flutter environments.
class ZenLoggerStrategyFlutter implements ZenLoggerStrategy {
  @override
  void log(String message, {bool isError = false}) {
    if (isError) {
      ZenLogger.instance.error(message);
    } else {
      ZenLogger.instance.info(message);
    }
  }
}

/// Returns the Flutter logging strategy.
ZenLoggerStrategy getStrategy() => ZenLoggerStrategyFlutter();
