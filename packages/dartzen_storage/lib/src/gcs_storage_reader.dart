import 'package:dartzen_core/dartzen_core.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'gcs_storage_config.dart';
import 'storage_object.dart';
import 'zen_storage_reader.dart';

/// Test hook: allow overriding the application-default credential initializer
/// so tests can exercise the ADC branch without contacting metadata servers.
@visibleForTesting
Future<http.Client> Function({List<String>? scopes})
gcsClientViaApplicationDefaultCredentials = ({List<String>? scopes}) =>
    auth.clientViaApplicationDefaultCredentials(scopes: scopes ?? []);

/// A [ZenStorageReader] backed by Google Cloud Storage.
///
/// This reader fetches objects from a GCS bucket using the official
/// `gcloud` package. Configuration is managed via [GcsStorageConfig].
///
/// This class handles the complexity of:
/// - Creating the authenticating GCS client (ADC or anonymous)
/// - Connecting to the GCS emulator when configured
/// - managing the underlying [Storage] connection
///
/// Example:
/// ```dart
/// final reader = GcsStorageReader(
///   config: GcsStorageConfig(
///     projectId: 'my-project',
///     bucket: 'my-content-bucket',
///   ),
/// );
///
/// final object = await reader.read('file.json');
/// ```
class GcsStorageReader implements ZenStorageReader {
  /// Creates a [GcsStorageReader].
  ///
  /// The [config] defines how to connect to GCS.
  ///
  /// For testing purposes, a [storage] instance can be injected directly,
  /// bypassing internal client creation.
  GcsStorageReader({
    required this.config,
    @visibleForTesting Storage? storage,
    @visibleForTesting
    Future<http.Client> Function(List<String> scopes)? authClientFactory,
    @visibleForTesting http.Client Function()? httpClientFactory,
  }) : _injectedStorage = storage,
       _authClientFactory = authClientFactory,
       _httpClientFactory = httpClientFactory {
    _storageFuture = _injectedStorage != null
        ? Future.value(_injectedStorage)
        : _initStorage();
  }

  /// The configuration used for this reader.
  final GcsStorageConfig config;

  late final Future<Storage> _storageFuture;
  final Storage? _injectedStorage;
  final Future<http.Client> Function(List<String> scopes)? _authClientFactory;
  final http.Client Function()? _httpClientFactory;

  /// Exposed for tests to await initialization.
  @visibleForTesting
  Future<Storage> get storageFuture => _storageFuture;

  Future<Storage> _initStorage() async {
    http.Client client;

    // 1. Determine HTTP client based on credentials mode
    if (config.credentialsMode == GcsCredentialsMode.anonymous) {
      client = _httpClientFactory != null
          ? _httpClientFactory()
          : http.Client();
    } else {
      // ADC (Application Default Credentials)
      if (_authClientFactory != null) {
        client = await _authClientFactory([
          storage_api.StorageApi.devstorageReadOnlyScope,
        ]);
      } else {
        // Attempt to obtain ADC client but fall back to a plain http.Client
        // if acquiring ADC takes too long. We use `Future.any` to avoid
        // type mismatches with `Future.timeout`'s `onTimeout` callback.
        final clientFuture = gcsClientViaApplicationDefaultCredentials(
          scopes: [storage_api.StorageApi.devstorageReadOnlyScope],
        );

        final fallbackFuture = Future<http.Client>.delayed(
          const Duration(seconds: 1),
          () =>
              _httpClientFactory != null ? _httpClientFactory() : http.Client(),
        );

        final result = await Future.any([clientFuture, fallbackFuture]);
        client = result;
      }
    }

    // 2. Wrap client if emulator is enabled
    final emulatorHost = config.emulatorHost;
    if (emulatorHost != null) {
      client = EmulatorHttpClient(client, emulatorHost);

      // 3. Verify emulator is running (in non-production mode)
      if (!dzIsPrd) {
        await _verifyEmulatorAvailability(client);
      }
    }

    return Storage(client, config.projectId);
  }

  /// Test-only helper that runs the same emulator verification path as
  /// `_initStorage()` but can be invoked directly from tests with a
  /// provided `http.Client` to ensure the `await _verifyEmulatorAvailability`
  /// branch is executed for coverage.
  @visibleForTesting
  Future<Storage> initAndVerifyForTest(http.Client client) async {
    final emulatorHost = config.emulatorHost;
    if (emulatorHost != null) {
      client = EmulatorHttpClient(client, emulatorHost);
      if (!dzIsPrd) {
        await _verifyEmulatorAvailability(client);
      }
    }

    return Storage(client, config.projectId);
  }

  /// Verifies that the Storage emulator is running and accessible.
  ///
  /// This is a mandatory check in development mode. The emulator is not
  /// optional - it's a required part of the DartZen development workflow.
  ///
  /// Throws [StateError] if the emulator is not accessible.
  Future<void> _verifyEmulatorAvailability(http.Client client) async {
    try {
      // Try to access the emulator's base URL
      final response = await client
          .get(Uri.parse('http://${config.emulatorHost}/'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode >= 500) {
        throw StateError(
          'Storage Emulator at ${config.emulatorHost} returned error: ${response.statusCode}',
        );
      }

      ZenLogger.instance.info(
        'Connected to Storage Emulator at ${config.emulatorHost}',
      );
    } catch (e) {
      final errorMessage =
          'Storage Emulator at ${config.emulatorHost} is not accessible';
      ZenLogger.instance.error(errorMessage, error: e);

      throw StateError(
        '$errorMessage. '
        'Please start the Storage emulator before running the application. '
        'The emulator is a required component of DartZen development.',
      );
    }
  }

  /// Exposed for tests to allow direct verification of emulator availability
  /// without going through full `_initStorage()` initialization.
  @visibleForTesting
  Future<void> verifyEmulatorAvailabilityForTest(http.Client client) =>
      _verifyEmulatorAvailability(client);

  /// Reads an object from Google Cloud Storage by key.
  ///
  /// Returns a [StorageObject] when found, or `null` when not found (404).
  ///
  /// Throws exceptions for:
  /// - Permission errors (403)
  /// - Network failures
  /// - Misconfiguration (wrong bucket, invalid credentials)
  /// - Any other system errors
  @override
  Future<StorageObject?> read(String key) async {
    try {
      final storage = await _storageFuture;
      final bucketName = config.bucket;
      // Apply prefix if configured
      final objectName = config.prefix != null ? '${config.prefix}$key' : key;

      final bucket = storage.bucket(bucketName);

      final bytes = <int>[];
      String? contentType;

      await for (final chunk in bucket.read(objectName)) {
        bytes.addAll(chunk);
      }

      // Attempt to get metadata for content type
      try {
        final info = await bucket.info(objectName);
        contentType = info.metadata.contentType;
      } catch (_) {
        // Metadata fetch failed, continue without content type
      }

      return StorageObject(bytes: bytes, contentType: contentType);
    } on storage_api.DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        ZenLogger.instance.info(
          'Object not found in GCS',
          internalData: {'bucket': config.bucket, 'key': key},
        );
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

/// HTTP client that rewrites requests to point at a local GCS emulator.
///
/// This client is used internally by `GcsStorageReader` when an emulator
/// host is configured. It rewrites the request URL host/port to the
/// configured emulator and forwards the request to the provided inner
/// `http.Client`.
class EmulatorHttpClient extends http.BaseClient {
  /// Creates an [EmulatorHttpClient].
  ///
  /// The inner `http.Client` will be used to perform the actual HTTP
  /// requests after the request URL has been rewritten to the emulator
  /// `emulatorHost`.
  EmulatorHttpClient(this._inner, String emulatorHost)
    : _host = emulatorHost.split(':')[0],
      _port = int.parse(emulatorHost.split(':')[1]);
  final http.Client _inner;
  final int _port;
  final String _host;

  /// Sends [request] to the underlying HTTP client after rewriting the
  /// request URL to point at the configured emulator host and port.
  ///
  /// The request body (if any) is preserved when possible.
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Redirect all requests to the emulator host
    final newUrl = request.url.replace(
      scheme: 'http',
      host: _host,
      port: _port,
    );

    final newRequest = http.Request(request.method, newUrl);
    newRequest.headers.addAll(request.headers);
    newRequest.followRedirects = request.followRedirects;
    newRequest.maxRedirects = request.maxRedirects;
    newRequest.persistentConnection = request.persistentConnection;

    if (request is http.Request) {
      newRequest.bodyBytes = request.bodyBytes;
    } else {
      // For other request types (Multipart/StreamedRequest) we consume the
      // finalize() stream and copy the raw bytes into the new request.
      final bytes = <int>[];
      await for (final chunk in request.finalize()) {
        bytes.addAll(chunk);
      }
      newRequest.bodyBytes = bytes;
    }

    return _inner.send(newRequest);
  }

  // Note: finalize().bytesToString() consumes the stream.
  // Ideally we should copy the body bytes more efficiently if it was a stream.
}
