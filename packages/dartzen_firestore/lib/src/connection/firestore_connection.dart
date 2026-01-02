import 'package:dartzen_core/dartzen_core.dart';
import 'package:http/http.dart' as http;

import 'firestore_config.dart';
import 'firestore_rest_client.dart';

/// Manages Firestore instance lifecycle and connection.
///
/// Provides a singleton [client] that is configured once via [initialize].
/// Supports both production and emulator modes with runtime availability checks.
abstract final class FirestoreConnection {
  static FirestoreRestClient? _client;
  static bool _initialized = false;

  /// Whether the connection has been initialized.
  static bool get isInitialized => _initialized;

  /// Returns the configured Firestore REST client.
  ///
  /// Throws [StateError] if [initialize] has not been called.
  static FirestoreRestClient get client {
    if (!_initialized || _client == null) {
      throw StateError(
        'FirestoreConnection has not been initialized. Call FirestoreConnection.initialize() first.',
      );
    }
    return _client!;
  }

  /// Initializes the Firestore connection with the given [config].
  ///
  /// This method must be called exactly once before accessing [client].
  ///
  /// In emulator mode, performs a runtime check to verify the emulator is running.
  /// Fails fast with a clear error if the emulator is configured but unavailable.
  ///
  /// [httpClient] is an optional HTTP client (useful for testing).
  ///
  /// Throws [StateError] if already initialized.
  static Future<void> initialize(
    FirestoreConfig config, {
    http.Client? httpClient,
  }) async {
    if (_initialized) {
      throw StateError('FirestoreConnection is already initialized.');
    }

    _client = FirestoreRestClient(config: config, httpClient: httpClient);

    if (!config.isProduction) {
      // Emulator mode
      final host = config.emulatorHost!;
      final port = config.emulatorPort!;

      ZenLogger.instance.info(
        'Connecting to Firestore Emulator at $host:$port',
      );

      // Runtime check: verify emulator is running by checking the base URL
      try {
        final client = httpClient ?? http.Client();
        final healthUrl = Uri.parse(
          'http://$host:$port/v1/projects/${config.projectId}/databases/(default)/documents',
        );
        final response = await client
            .get(healthUrl)
            .timeout(const Duration(seconds: 2));

        // Accept any response (200, 400, etc.) - just verify emulator is listening
        if (response.statusCode >= 500) {
          throw http.ClientException(
            'Emulator returned error: ${response.statusCode}',
          );
        }

        if (httpClient == null) {
          client.close();
        }
      } catch (e) {
        final errorMessage =
            'Firestore Emulator at $host:$port is not accessible';
        ZenLogger.instance.error(errorMessage, error: e);

        throw StateError(
          '$errorMessage. '
          'Please start the Firestore emulator before running the application.',
        );
      }
    } else {
      // Production mode
      ZenLogger.instance.info('Connected to Firestore (production mode)');
    }

    _initialized = true;
  }

  /// Resets the connection state.
  ///
  /// This is primarily for testing purposes.
  /// In production code, [initialize] should only be called once.
  static void reset() {
    _client = null;
    _initialized = false;
  }
}
