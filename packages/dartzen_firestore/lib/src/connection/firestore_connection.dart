import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/src/connection/firestore_config.dart';
import 'package:dartzen_firestore/src/l10n/firestore_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Manages Firestore instance lifecycle and connection.
///
/// Provides a singleton [instance] that is configured once via [initialize].
/// Supports both production and emulator modes with runtime availability checks.
abstract final class FirestoreConnection {
  static FirebaseFirestore? _instance;
  static bool _initialized = false;

  /// Returns the configured Firestore instance.
  ///
  /// Throws [StateError] if [initialize] has not been called.
  static FirebaseFirestore get instance {
    if (!_initialized || _instance == null) {
      throw StateError(
        'FirestoreConnection has not been initialized. Call FirestoreConnection.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initializes the Firestore connection with the given [config].
  ///
  /// This method must be called exactly once before accessing [instance].
  ///
  /// In emulator mode, performs a runtime check to verify the emulator is running.
  /// Fails fast with a clear error if the emulator is configured but unavailable.
  ///
  /// [localization] is used for localized log messages.
  /// [language] is the language code for localization (defaults to 'en').
  ///
  /// Throws [StateError] if already initialized.
  static Future<void> initialize(
    FirestoreConfig config, {
    required ZenLocalizationService localization,
    String language = 'en',
  }) async {
    if (_initialized) {
      throw StateError('FirestoreConnection is already initialized.');
    }

    // Load localization messages for firestore module
    await localization.loadModuleMessages(
      'firestore',
      language,
      modulePath: 'lib/src/l10n',
    );

    final messages = FirestoreMessages(localization, language);
    _instance = FirebaseFirestore.instance;

    if (!config.isProduction) {
      // Emulator mode
      final host = config.emulatorHost!;
      final port = config.emulatorPort!;

      _instance!.useFirestoreEmulator(host, port);

      // Runtime check: verify emulator is running
      try {
        // Attempt a simple read operation to verify connectivity
        await _instance!
            .collection('_health_check')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 2));

        ZenLogger.instance.warn(messages.emulatorConnection(host, port));
      } catch (e) {
        final errorMessage = messages.emulatorUnavailable(host, port);
        ZenLogger.instance.error(errorMessage, error: e);

        throw StateError(
          '$errorMessage. '
          'Please start the Firestore emulator before running the application.',
        );
      }
    } else {
      // Production mode
      ZenLogger.instance.info(messages.productionConnection());
    }

    _initialized = true;
  }

  /// Resets the connection state.
  ///
  /// This is primarily for testing purposes.
  /// In production code, [initialize] should only be called once.
  static void reset() {
    _instance = null;
    _initialized = false;
  }
}
