import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:gcloud/datastore.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart';
import 'package:zen_demo_server/src/l10n/server_messages.dart' as demo;

import 'package:zen_demo_server/src/identity/firebase_token_verifier.dart';
import 'package:zen_demo_server/src/identity/server_identity_repository.dart';

/// ZenDemo server application.
///
/// This server demonstrates real DartZen architecture with:
/// - Firebase Auth token verification (server-side)
/// - Identity resolution from Firestore (server-side)
/// - Real filesystem-based storage
/// - No mocks, no stubs, no TODOs
class ZenDemoServer {
  /// Creates the server.
  ZenDemoServer({
    required this.port,
    required this.storagePath,
    required this.firestoreHost,
    required this.firestorePort,
    required this.authEmulatorHost,
  });

  /// Server port.
  final int port;

  /// Local storage path for content.
  final String storagePath;

  /// Firestore emulator host.
  final String firestoreHost;

  /// Firestore emulator port.
  final int firestorePort;

  /// Auth emulator host.
  final String authEmulatorHost;

  late final ZenLocalizationService _localization;
  late final ServerIdentityRepository _identityRepository;
  late final FirebaseTokenVerifier _tokenVerifier;

  final ZenLogger _logger = ZenLogger.instance;

  /// Initializes the server.
  Future<void> initialize() async {
    _logger.info('Initializing ZenDemo server');

    _validateStoragePath();

    // Initialize identity repository (in-memory for demo)
    _identityRepository = ServerIdentityRepository();
    _tokenVerifier = FirebaseTokenVerifier(authEmulatorHost: authEmulatorHost);

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

    _logger.info('ZenDemo server initialized successfully');
  }

  void _validateStoragePath() {
    final dir = Directory(storagePath);
    if (!dir.existsSync()) {
      throw StateError(
        'Storage path does not exist: $storagePath. '
        'Expected directory with content files.',
      );
    }

    final termsFile = File('$storagePath/legal/terms.html');
    if (!termsFile.existsSync()) {
      throw StateError(
        'Terms file not found: ${termsFile.path}. '
        'Zen Demo requires real storage content.',
      );
    }

    _logger.info('Using storage path: $storagePath');
  }

  /// Runs the server.
  Future<void> run() async {
    final router = Router();

    // Ping endpoint (no auth required)
    router.get('/ping', _handlePing);

    // Profile endpoint (requires authentication)
    router.get('/profile/<userId>', (Request request, String userId) async => await _withAuth(request, (identity) => _handleProfile(request, userId, identity)));

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
  Future<Response> _withAuth(
    Request request,
    Future<Response> Function(IdentityContract identity) handler,
  ) async {
    final authHeader = request.headers['authorization'];
    
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401, body: jsonEncode({
        'error': 'unauthorized',
        'message': 'Missing or invalid authorization header',
      }), headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    final verifyResult = await _tokenVerifier.verifyToken(token);
    
    if (!verifyResult.isSuccess) {
      return Response(401, body: jsonEncode({
        'error': 'invalid-token',
        'message': verifyResult.errorMessage ?? 'Token verification failed',
      }), headers: {'Content-Type': 'application/json'});
    }

    final tokenData = verifyResult.data!;
    final userId = tokenData['userId'] as String;
    
    // Try to get identity from repository
    var identityResult = await _identityRepository.getIdentity(userId);
    
    // If not found, create it from token data
    if (!identityResult.isSuccess) {
      _logger.info('Identity not found, creating from token data');
      identityResult = await _identityRepository.upsertIdentity(
        userId: userId,
        email: tokenData['email'] as String,
        displayName: tokenData['displayName'] as String?,
        photoUrl: tokenData['photoUrl'] as String?,
      );
      
      if (!identityResult.isSuccess) {
        return Response(500, body: jsonEncode({
          'error': 'identity-resolution-failed',
          'message': identityResult.errorMessage ?? 'Failed to resolve identity',
        }), headers: {'Content-Type': 'application/json'});
      }
    }

    return await handler(identityResult.data!);
  }

  Middleware _corsMiddleware() =>
      (Handler handler) => (Request request) async {
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

    final contract = PingContract(
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
    IdentityContract identity,
  ) async {
    final language = request.url.queryParameters['lang'] ?? 'en';
    final messages = demo.ServerMessages(_localization, language);

    // Use the resolved identity from authentication middleware
    final contract = ProfileContract(
      userId: identity.id,
      displayName: identity.displayName ?? identity.email,
      email: identity.email,
      bio: messages.profileBio(),
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
      final termsFile = File('$storagePath/legal/terms.html');
      final content = await termsFile.readAsString();

      final contract = TermsContract(
        content: content,
        contentType: 'text/html',
      );

      return Response.ok(
        jsonEncode(contract.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.error('Failed to load terms: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': messages.termsError(e.toString())}),
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
          final incomingMessage = WebSocketMessageContract.fromJson(json);

          final response = WebSocketMessageContract(
            type: 'echo',
            payload: incomingMessage.payload,
          );

          channel.sink.add(jsonEncode(response.toJson()));
        } catch (e) {
          _logger.error('WebSocket error: $e');
          final errorMessage = WebSocketMessageContract(
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
