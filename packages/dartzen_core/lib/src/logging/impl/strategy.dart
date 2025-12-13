/// Internal strategy for logging.
abstract class ZenLoggerStrategy {
  /// Logs a [message]. [isError] indicates if it's an error level log.
  void log(String message, {bool isError = false});
}
