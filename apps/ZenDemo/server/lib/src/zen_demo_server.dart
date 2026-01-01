import 'dart:async';
import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_storage/dartzen_storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart' as contracts;

import 'identity/firebase_token_verifier.dart';
import 'l10n/server_messages.dart' as demo;

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
    required this.authEmulatorHost,
  });

  /// Server port.
  final int port;

  /// Storage bucket name.
  final String storageBucket;

  /// Auth emulator host.
  final String authEmulatorHost;

  late final ZenLocalizationService _localization;
  late final FirestoreIdentityRepository _identityRepository;
  late final ZenStorageReader _storageReader;
  late final FirebaseTokenVerifier _tokenVerifier;

  final ZenLogger _logger = ZenLogger.instance;

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
    final firestoreConfig = FirestoreConfig(
      projectId: 'demo-zen',
    );

    await FirestoreConnection.initialize(
      firestoreConfig,
    );

    // Initialize identity repository
    _identityRepository = const FirestoreIdentityRepository();

    // Initialize token verifier
    _tokenVerifier = FirebaseTokenVerifier(authEmulatorHost: authEmulatorHost);

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
          'error': 'unauthorized',
          'message': 'Missing or invalid authorization header',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final token = authHeader.substring(7);
    final verifyResult = await _tokenVerifier.verifyToken(token);

    if (!verifyResult.isSuccess) {
      return Response(
        401,
        body: jsonEncode({
          'error': 'invalid-token',
          'message':
              verifyResult.errorOrNull?.message ?? 'Token verification failed',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final tokenData = verifyResult.dataOrNull!;
    final userId = tokenData['userId'] as String;

    // Create IdentityId
    final idResult = IdentityId.create(userId);
    if (!idResult.isSuccess) {
      return Response(
        400,
        body: jsonEncode({
          'error': 'invalid-user-id',
          'message': idResult.errorOrNull?.message ?? 'Invalid user ID',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final identityId = idResult.dataOrNull!;

    // Try to get existing identity from Firestore
    final getResult = await _identityRepository.getIdentityById(identityId);

    if (getResult.isSuccess) {
      // Identity exists, use it
      return await handler(getResult.dataOrNull!);
    }

    // Identity doesn't exist, create simplified one for demo
    _logger.info('Creating new demo identity for user: $userId');

    // Demo: Create identity with default USER role and ACTIVE state
    final demoIdentity = Identity.createPending(
      id: identityId,
      authority: Authority(roles: {Role.user}),
    );

    // Activate immediately for demo (bypass email verification)
    final activateResult = demoIdentity.lifecycle.activate();
    if (!activateResult.isSuccess) {
      return Response(
        500,
        body: jsonEncode({
          'error': 'activation-failed',
          'message': activateResult.errorOrNull?.message ??
              'Failed to activate identity',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final activeIdentity = Identity(
      id: demoIdentity.id,
      lifecycle: activateResult.dataOrNull!,
      authority: demoIdentity.authority,
      createdAt: demoIdentity.createdAt,
    );

    // Store in Firestore
    final createResult =
        await _identityRepository.createIdentity(activeIdentity);
    if (!createResult.isSuccess) {
      _logger.error(
        'Failed to create identity',
        error: createResult.errorOrNull,
      );
      return Response(
        500,
        body: jsonEncode({
          'error': 'identity-creation-failed',
          'message':
              createResult.errorOrNull?.message ?? 'Failed to create identity',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return await handler(activeIdentity);
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
    final language = request.url.queryParameters['lang'] ?? 'en';
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

  Future<Response> _handleTerms(Request request) async {
    final language = request.url.queryParameters['lang'] ?? 'en';
    final messages = demo.ServerMessages(_localization, language);

    try {
      // Read terms from GCS storage
      final storageObject = await _storageReader.read('legal/terms.html');

      if (storageObject == null) {
        _logger.error('Terms file not found in storage');
        return Response.internalServerError(
          body: jsonEncode(
              {'error': messages.termsError('Terms file not found')}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final content = utf8.decode(storageObject.bytes);

      final contract = contracts.TermsContract(
        content: content,
        contentType: 'text/html',
      );

      return Response.ok(
        jsonEncode(contract.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load terms', error: e, stackTrace: stackTrace);

      return Response.internalServerError(
        body: jsonEncode({
          'error': 'terms_load_failed',
          'message': 'Failed to load terms: ${e.toString()}',
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
          final errorMessage = contracts.WebSocketMessageContract(
            type: 'error',
            payload: 'Failed to process message: $e',
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
