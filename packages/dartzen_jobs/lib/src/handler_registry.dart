import 'models/job_context.dart';

/// Registry for job handlers. Handlers are registered separately from descriptors.
///
/// Use `HandlerRegistry.register` during app startup to make handlers
/// discoverable to `Executor` implementations and `JobRunner` instances.
class HandlerRegistry {
  static final Map<String, Future<void> Function(JobContext)> _handlers = {};

  /// Register a handler for a job id.
  static void register(String id, Future<void> Function(JobContext) handler) {
    _handlers[id] = handler;
  }

  /// Get a handler previously registered, or null if none exists.
  static Future<void> Function(JobContext)? get(String id) => _handlers[id];

  /// Clear all registered handlers (mostly useful for tests).
  static void clear() => _handlers.clear();
}
