import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'middleware/transport_middleware.dart';
import 'zen_server_config.dart';
import 'zen_server_router.dart';

/// The main application runtime for DartZen server applications.
///
/// This is the entry point for wiring together:
/// - Domain features
/// - Infrastructure utilities
/// - Transport layer
///
/// Responsibilities:
/// - Process lifecycle (startup and graceful shutdown)
/// - Request routing
/// - Middleware pipeline configuration
///
/// This is a Shelf-native, GCP-native runtime designed for Cloud Run deployment.
///
/// ## Execution Model
///
/// The server operates in a **single event-loop runtime**:
/// - All requests share one execution thread
/// - No CPU-intensive work in request handlers
/// - No synchronous I/O operations
/// - All long-running work must be delegated to jobs
///
/// Request handlers MUST be non-blocking. Blocking operations
/// will freeze the entire server, affecting all active requests.
///
/// See `/docs/execution_model.md` for detailed constraints.
class ZenServerApplication {
  /// Creates a [ZenServerApplication] with the given [config].
  ZenServerApplication({required this.config});

  /// The server configuration.
  final ZenServerConfig config;

  HttpServer? _server;
  final List<FutureOr<void> Function()> _onStartup = [];
  final List<FutureOr<void> Function()> _onShutdown = [];
  StreamSubscription<ProcessSignal>? _sigintSubscription;
  StreamSubscription<ProcessSignal>? _sigtermSubscription;

  /// Registers a hook to be called during server startup.
  void onStartup(FutureOr<void> Function() hook) => _onStartup.add(hook);

  /// Registers a hook to be called during server shutdown.
  void onShutdown(FutureOr<void> Function() hook) => _onShutdown.add(hook);

  /// Starts the server and begins listening for requests.
  Future<void> run() async {
    // 1. Execute startup hooks
    for (final hook in _onStartup) {
      await hook();
    }

    // 2. Configure the pipeline
    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(zenServerTransportMiddleware())
        .addHandler(
          ZenServerRouter(
            config.contentProvider,
            contentRoutes: config.contentRoutes,
          ).router.call,
        );

    // 3. Start the server
    _server = await io.serve(pipeline, config.bindAddress, config.port);

    // 4. Setup graceful shutdown
    _sigintSubscription = ProcessSignal.sigint.watch().listen((_) => stop());
    _sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) => stop());
  }

  /// Stops the server gracefully.
  Future<void> stop() async {
    if (_server == null) return;

    // 1. Cancel signal listeners
    await _sigintSubscription?.cancel();
    await _sigtermSubscription?.cancel();
    _sigintSubscription = null;
    _sigtermSubscription = null;

    // 2. Execute shutdown hooks
    for (final hook in _onShutdown) {
      await hook();
    }

    // 3. Close the server
    await _server?.close(force: true);
    _server = null;
  }
}
