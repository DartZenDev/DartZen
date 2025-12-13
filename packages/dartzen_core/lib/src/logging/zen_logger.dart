import 'impl/strategy_stub.dart'
    if (dart.library.io) 'impl/strategy_io.dart'
    if (dart.library.ui) 'impl/strategy_flutter.dart';

/// Minimal logging abstraction for DartZen.
///
/// Use [ZenLogger.instance] to log messages.
/// Do NOT instantiate your own logger in feature packages.
abstract class ZenLogger {
  /// The shared logger instance.
  static ZenLogger instance = _DefaultZenLogger();

  /// Logs a debug message (dev diagnostics).
  void debug(String message);

  /// Logs an info message (general events).
  void info(String message);

  /// Logs a warning message (potential issues).
  void warn(String message);

  /// Logs an error message (failures).
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default implementation using configured strategy (IO vs Flutter).
class _DefaultZenLogger implements ZenLogger {
  final _strategy = getStrategy();

  @override
  void debug(String message) {
    _log('[DEBUG] $message');
  }

  @override
  void info(String message) {
    _log('[INFO] $message');
  }

  @override
  void warn(String message) {
    _log('[WARN] $message');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final sb = StringBuffer('[ERROR] $message');
    if (error != null) sb.write('\n$error');
    if (stackTrace != null) sb.write('\n$stackTrace');
    _log(sb.toString(), isError: true);
  }

  void _log(String line, {bool isError = false}) {
    _strategy.log(line, isError: isError);
  }
}
