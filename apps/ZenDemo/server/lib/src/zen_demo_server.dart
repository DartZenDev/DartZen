import 'dart:async';
import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:dartzen_identity/server.dart' as identity_server;
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart' as contracts;

import 'l10n/server_messages.dart' as demo;
import 'services/auth_service.dart';
import 'services/identity_service.dart';

/// ZenDemo server application.
///
/// This server demonstrates real DartZen architecture with:
/// - Firebase Auth token verification (server-side)
/// - Identity resolution from Firestore via REST API (server-side)
/// - Cloud Storage via emulator (server-side)
/// - No mocks, no stubs, no TODOs
class ZenDemoServer {
  /// Creates the server.
  ZenDemoServer({
    required this.port,
    required this.storageBucket,
  });

  /// Server port.
  final int port;

  /// Storage bucket name.
  final String storageBucket;

  late final ZenLocalizationService _localization;
  late final FirestoreIdentityRepository _identityRepository;
  late final ZenStorageReader _storageReader;
  late final identity_server.IdentityTokenVerifier _tokenVerifier;
  late final AuthService _authService;
  late final IdentityService _identityService;

  final ZenLogger _logger = ZenLogger.instance;

  static const _defaultLanguage = 'en';

  /// Initializes the server.
  Future<void> initialize() async {
    _logger.info('Initializing ZenDemo server');

    // Initialize localization first
    const localizationConfig = ZenLocalizationConfig(
      isProduction: false,
      globalPath: 'lib/src/l10n',
    );
    _localization = ZenLocalizationService(config: localizationConfig);
    await _localization.loadModuleMessages(
      'zen_demo',
      'en',
      modulePath: 'lib/src/l10n',
    );
    await _localization.loadModuleMessages(
      'zen_demo',
      'pl',
      modulePath: 'lib/src/l10n',
    );

    // Initialize Firestore connection
    // Automatically uses emulator if FIRESTORE_EMULATOR_HOST is set
    // projectId is auto-read from GCLOUD_PROJECT environment variable
    final firestoreConfig = FirestoreConfig();

    await FirestoreConnection.initialize(
      firestoreConfig,
    );

    // Initialize identity repository
    _identityRepository = const FirestoreIdentityRepository();

    // Initialize token verifier
    // Uses GCLOUD_PROJECT from environment (set in run.sh)
    _tokenVerifier = identity_server.IdentityTokenVerifier(
      config: identity_server.IdentityTokenVerifierConfig(),
    );

    _authService = AuthService(authUrl: _buildAuthUrl());
    _identityService = IdentityService(repository: _identityRepository);

    // Initialize Firebase Storage reader for emulator
    _storageReader = FirebaseStorageReader(
      config: FirebaseStorageConfig(
        bucket: storageBucket,
      ),
    );

    _logger.info('ZenDemo server initialized successfully');
  }

  /// Runs the server.
  Future<void> run() async {
    final router = Router();

    // Ping endpoint (no auth required)
    router.get('/ping', _handlePing);

    // Login endpoint (no auth required)
    router.post('/login', _handleLogin);

    // Profile endpoint (requires authentication)
    router.get(
        '/profile/<userId>',
        (Request request, String userId) async => await _withAuth(
            request, (identity) => _handleProfile(request, userId, identity)));

    // Terms endpoint (no auth required)
    router.get('/terms', _handleTerms);

    // WebSocket endpoint
    router.get('/ws', webSocketHandler(_handleWebSocket));

    // CORS middleware
    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    final server = await serve(handler, 'localhost', port);
    _logger.info('ZenDemo server listening on port ${server.port}');
  }

  /// Middleware to verify authentication and resolve identity.
  ///
  /// This creates simplified Identity domain objects for demo purposes:
  /// - Default role: USER
  /// - State: ACTIVE (auto-activated)
  /// - Minimal verification facts
  Future<Response> _withAuth(
    Request request,
    Future<Response> Function(Identity identity) handler,
  ) async {
    final authHeader = request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(
        401,
        body: jsonEncode({
          'error': AuthError.missingAuthHeader.code,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final token = authHeader.substring(7);
    final verifyResult = await _tokenVerifier.verifyToken(token);

    if (!verifyResult.isSuccess) {
      _logger.error(
        'Token verification failed',
        error: verifyResult.errorOrNull,
      );
      return Response(
        401,
        body: jsonEncode({
          'error': AuthError.invalidToken.code,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final externalData = verifyResult.dataOrNull!;
    final userId = externalData.userId;

    // Create IdentityId
    final idResult = IdentityId.create(userId);
    if (!idResult.isSuccess) {
      _logger.error('Invalid user ID', error: idResult.errorOrNull);
      return Response(
        400,
        body: jsonEncode({
          'error': 'invalid_user_id',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final identityId = idResult.dataOrNull!;

    // Try to get existing identity from Firestore
    final identityResult =
        await _identityService.getOrCreateDemoIdentity(identityId);
    if (!identityResult.isSuccess) {
      return Response(
        500,
        body: jsonEncode({
          'error': IdentityError.createFailed.code,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return await handler(identityResult.dataOrNull!);
  }

  Middleware _corsMiddleware() => (Handler handler) => (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok(
            '',
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            },
          );
        }

        final response = await handler(request);
        return response.change(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        );
      };

  Future<Response> _handlePing(Request request) async {
    final language = request.headers['accept-language'] ?? _defaultLanguage;
    final messages = demo.ServerMessages(_localization, language);

    final contract = contracts.PingContract(
      message: messages.pingSuccess(),
      timestamp: DateTime.now().toIso8601String(),
    );

    return Response.ok(
      jsonEncode(contract.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleLogin(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final email = json['email'] as String?;
      final password = json['password'] as String?;

      if (email == null || password == null) {
        return Response(
          400,
          body: jsonEncode({
            'error': AuthError.invalidCredentials.code,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final authResult = await _authService.authenticate(
        email: email,
        password: password,
      );

      if (!authResult.isSuccess) {
        final error = authResult.errorOrNull!;
        _logger.error('Authentication failed: ${error.message}');
        return Response(
          401,
          body: jsonEncode({
            'error': error.message,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final authData = authResult.dataOrNull!;
      final idToken = authData['idToken'] as String;
      final userId = authData['localId'] as String;

      return Response.ok(
        jsonEncode({
          'idToken': idToken,
          'userId': userId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      _logger.error('Login error: $e', stackTrace: stack);
      return Response(
        500,
        body: jsonEncode({
          'error': 'login_failed',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleProfile(
    Request request,
    String userId,
    Identity identity,
  ) async {
    // Demo: Extract basic info from Identity domain model
    // In a real app, you'd query a separate profile service
    final contract = contracts.ProfileContract(
      userId: identity.id.value,
      displayName: 'Demo User',
      email: '${identity.id.value}@demo.local',
      bio: 'Demo profile - Identity managed in Firestore',
    );

    return Response.ok(
      jsonEncode(contract.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Uri _buildAuthUrl() {
    final apiKey = dzGcloudProject.isEmpty ? 'demo-api-key' : dzGcloudProject;
    return dzIsPrd
        ? Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey')
        : Uri.parse(
            'http://$dzIdentityToolkitEmulatorHost/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
  }

  Future<Response> _handleTerms(Request request) async {
    try {
      // Get language from Accept-Language header, default to 'en'
      final language = request.headers['accept-language'] ?? _defaultLanguage;

      // Construct file path using language code: terms.{lang}.md
      final filePath = 'legal/terms.$language.md';

      _logger.info('Loading terms for language: $language (path: $filePath)');

      // Read terms from GCS storage
      final storageObject = await _storageReader.read(filePath);

      if (storageObject == null) {
        _logger.error('Terms file not found in storage: $filePath');
        return Response.internalServerError(
          body: jsonEncode({'error': TermsError.notFound.code}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final content = utf8.decode(storageObject.bytes);

      final contract = contracts.TermsContract(
        content: content,
        contentType: 'text/markdown',
      );

      return Response.ok(
        jsonEncode(contract.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load terms', error: e, stackTrace: stackTrace);

      return Response.internalServerError(
        body: jsonEncode({
          'error': TermsError.loadFailed.code,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  void _handleWebSocket(WebSocketChannel channel) {
    _logger.info('WebSocket connection established');

    channel.stream.listen(
      (dynamic message) {
        try {
          final json = jsonDecode(message as String) as Map<String, dynamic>;
          final incomingMessage =
              contracts.WebSocketMessageContract.fromJson(json);

          final response = contracts.WebSocketMessageContract(
            type: 'echo',
            payload: incomingMessage.payload,
          );

          channel.sink.add(jsonEncode(response.toJson()));
        } catch (e) {
          _logger.error('WebSocket error: $e');
          // WebSocket payload is for debugging, not user-facing
          const errorMessage = contracts.WebSocketMessageContract(
            type: 'error',
            payload: 'ws_message_error',
          );
          channel.sink.add(jsonEncode(errorMessage.toJson()));
        }
      },
      onDone: () {
        _logger.info('WebSocket connection closed');
      },
      onError: (dynamic error) {
        _logger.error('WebSocket error: $error');
      },
    );
  }
}

/// Error codes for terms retrieval.
enum TermsError {
  /// Terms file missing in storage.
  notFound,

  /// Failed to load or decode the terms content.
  loadFailed,
}

/// String codes for [TermsError].
extension TermsErrorCode on TermsError {
  /// Returns the string representation expected by the client.
  String get code => name;
}
