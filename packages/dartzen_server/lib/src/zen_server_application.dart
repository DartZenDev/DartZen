import 'dart:async';
import 'dart:io';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'zen_server_config.dart';
import 'zen_server_router.dart';

/// The main application boundary for the DartZen server.
///
/// Responsible for lifecycle management, adapter orchestration,
/// and transport pipeline configuration.
class ZenServerApplication {
  /// Creates a [ZenServerApplication] with the given [config].
  ZenServerApplication({required this.config});

  /// The server configuration.
  final ZenServerConfig config;

  HttpServer? _server;
  final List<FutureOr<void> Function()> _onStartup = [];
  final List<FutureOr<void> Function()> _onShutdown = [];

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
        .addMiddleware(transportMiddleware())
        .addHandler(ZenServerRouter(config.staticContentProvider).router.call);

    // 3. Start the server
    _server = await io.serve(pipeline, config.bindAddress, config.port);

    // 4. Setup graceful shutdown
    ProcessSignal.sigint.watch().listen((_) => stop());
    ProcessSignal.sigterm.watch().listen((_) => stop());
  }

  /// Stops the server gracefully.
  Future<void> stop() async {
    if (_server == null) return;

    // 1. Execute shutdown hooks
    for (final hook in _onShutdown) {
      await hook();
    }

    // 2. Close the server
    await _server?.close(force: true);
    _server = null;
  }
}
