import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:dartzen_ui_admin/dartzen_ui_admin.dart';
import 'package:dartzen_ui_identity/dartzen_ui_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'mock_admin_transport.dart';

// ---------------------------------------------------------------------------
// Mock transport handler
// ---------------------------------------------------------------------------

final _mockHandler = MockAdminTransport();

// ---------------------------------------------------------------------------
// Mock identity repository
// ---------------------------------------------------------------------------

/// A fake [IdentityRepository] for the example.
///
/// Accepts any email with password `"password"` and returns a
/// hard-coded identity. In a real app this would be backed
/// by `dartzen_identity`'s Firestore or REST repository.
class _MockIdentityRepository implements IdentityRepository {
  IdentityContract? _current;

  static final _demoIdentity = IdentityContract(
    id: 'demo-user-1',
    lifecycle: const IdentityLifecycleContract(state: 'active'),
    authority: const AuthorityContract(
      roles: ['admin'],
      capabilities: ['admin.read', 'admin.write', 'admin.delete'],
    ),
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );

  @override
  Future<ZenResult<IdentityContract?>> getCurrentIdentity() async =>
      ZenResult.ok(_current);

  @override
  Future<ZenResult<IdentityContract>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    if (password == 'password') {
      _current = _demoIdentity;
      return ZenResult.ok(_demoIdentity);
    }

    return const ZenResult.err(
      ZenUnauthorizedError(
        'Invalid email or password '
        '(try password="password")',
      ),
    );
  }

  @override
  Future<ZenResult<IdentityContract>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    _current = _demoIdentity;
    return ZenResult.ok(_demoIdentity);
  }

  @override
  Future<ZenResult<void>> restorePassword({required String email}) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const ZenResult.ok(null);
  }

  @override
  Future<ZenResult<void>> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _current = null;
    return const ZenResult.ok(null);
  }
}

// ---------------------------------------------------------------------------
// Admin client (mock transport)
// ---------------------------------------------------------------------------

/// Wraps [MockAdminTransport] in a [ZenAdminClient]-compatible layer.
class _ExampleAdminClient extends ZenAdminClient {
  _ExampleAdminClient()
    : super(
        transport: ZenTransport(
          config: const ZenTransportConfig(isProd: false, isTest: true),
        ),
      );

  @override
  Future<ZenAdminPage<Map<String, dynamic>>> query(
    String resourceName,
    ZenAdminQuery query,
  ) async {
    final result = await _mockHandler.handle(
      const TransportDescriptor(
        id: 'admin.query',
        channel: TransportChannel.http,
        reliability: TransportReliability.atMostOnce,
      ),
      {
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/query',
        'offset': query.offset,
        'limit': query.limit,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Query failed');
    }

    final data = result.data as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>;
    final items = rawItems
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();

    return ZenAdminPage<Map<String, dynamic>>(
      items: items,
      total: data['total'] as int,
      offset: data['offset'] as int,
      limit: data['limit'] as int,
    );
  }

  @override
  Future<Map<String, dynamic>> fetchById(String resourceName, String id) async {
    final result = await _mockHandler.handle(
      const TransportDescriptor(
        id: 'admin.fetch',
        channel: TransportChannel.http,
        reliability: TransportReliability.atMostOnce,
      ),
      {
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/$id',
        'id': id,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Fetch failed');
    }

    return Map<String, dynamic>.from(result.data as Map<dynamic, dynamic>);
  }

  @override
  Future<void> create(String resourceName, Map<String, dynamic> data) async {
    final result = await _mockHandler.handle(
      const TransportDescriptor(
        id: 'admin.create',
        channel: TransportChannel.http,
        reliability: TransportReliability.atLeastOnce,
      ),
      {
        'resource': resourceName,
        'path': '/v1/admin/$resourceName',
        'data': data,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Create failed');
    }
  }

  @override
  Future<void> update(
    String resourceName,
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _mockHandler.handle(
      const TransportDescriptor(
        id: 'admin.update',
        channel: TransportChannel.http,
        reliability: TransportReliability.atLeastOnce,
      ),
      {
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/$id',
        'id': id,
        'data': data,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Update failed');
    }
  }

  @override
  Future<void> delete(String resourceName, String id) async {
    final result = await _mockHandler.handle(
      const TransportDescriptor(
        id: 'admin.delete',
        channel: TransportChannel.http,
        reliability: TransportReliability.atLeastOnce,
      ),
      {
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/$id',
        'id': id,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Delete failed');
    }
  }
}

// ---------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        zenAdminClientProvider.overrideWithValue(_ExampleAdminClient()),
        identityRepositoryProvider.overrideWithValue(_MockIdentityRepository()),
      ],
      child: const AdminExampleApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Root app widget
// ---------------------------------------------------------------------------

/// Root widget for the admin example app.
///
/// Demonstrates how to protect admin routes behind a login
/// screen using `go_router` redirect + `identitySessionStoreProvider`.
class AdminExampleApp extends ConsumerStatefulWidget {
  const AdminExampleApp({super.key});

  @override
  ConsumerState<AdminExampleApp> createState() => _AdminExampleAppState();
}

class _AdminExampleAppState extends ConsumerState<AdminExampleApp> {
  late ZenAdminMessages _adminMessages;
  late IdentityMessages _identityMessages;
  late GoRouter _router;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final service = ZenLocalizationService(
      config: const ZenLocalizationConfig(
        isProduction: false,
        globalPath: 'assets/l10n',
      ),
    );

    try {
      await service.loadModuleMessages(
        ZenAdminMessages.module,
        'en',
        modulePath: 'packages/dartzen_ui_admin/lib/src/l10n',
      );
      await service.loadModuleMessages(
        IdentityMessages.module,
        'en',
        modulePath: 'packages/dartzen_ui_identity/lib/src/l10n',
      );
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    _adminMessages = ZenAdminMessages(service, 'en');
    _identityMessages = IdentityMessages(service, 'en');
    _router = _buildRouter();

    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  // -----------------------------------------------------------------------
  // Router with auth guard
  // -----------------------------------------------------------------------

  GoRouter _buildRouter() => GoRouter(
    initialLocation: '/admin',
    redirect: (context, state) {
      final session = ref.read(identitySessionStoreProvider);
      final isAuthenticated = session.asData?.value != null;
      final isOnLogin = state.matchedLocation.startsWith('/login');

      // Not authenticated → force login.
      if (!isAuthenticated && !isOnLogin) return '/login';
      // Authenticated but still on login → go to admin.
      if (isAuthenticated && isOnLogin) return '/admin';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              Expanded(
                child: LoginScreen(
                  messages: _identityMessages,
                  onLoginSuccess: () => context.go('/admin'),
                  onRegisterClick: () => context.go('/register'),
                  onForgotPasswordClick: () => context.go('/restore'),
                ),
              ),
              MaterialBanner(
                content: const Text(
                  'Demo credentials — '
                  'email: any, password: "password"',
                ),
                leading: const Icon(Icons.info_outline),
                actions: const [SizedBox.shrink()],
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          messages: _identityMessages,
          onRegisterSuccess: () => context.go('/admin'),
          onLoginClick: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/restore',
        builder: (context, state) => RestorePasswordScreen(
          messages: _identityMessages,
          onRestoreSuccess: () => context.go('/login'),
          onBackClick: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => _AdminHome(
          adminMessages: _adminMessages,
          identityMessages: _identityMessages,
        ),
      ),
    ],
  );

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final lightScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'Admin UI Example',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        extensions: [AdminThemeExtension.fromColorScheme(lightScheme)],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        extensions: [AdminThemeExtension.fromColorScheme(darkScheme)],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin home screen
// ---------------------------------------------------------------------------

class _AdminHome extends ConsumerWidget {
  final ZenAdminMessages adminMessages;
  final IdentityMessages identityMessages;

  const _AdminHome({
    required this.adminMessages,
    required this.identityMessages,
  });

  static final _resource = ZenAdminResource<Map<String, dynamic>>(
    resourceName: 'users',
    displayName: 'Users',
    fields: const [
      ZenAdminField(name: 'id', label: 'ID', editable: false),
      ZenAdminField(name: 'name', label: 'Name', required: true),
      ZenAdminField(name: 'email', label: 'Email'),
    ],
    permissions: const ZenAdminPermissions(
      canRead: true,
      canWrite: true,
      canDelete: true,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(zenAdminClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(adminMessages.listTitle),
        actions: [
          // Logout button — demonstrates session teardown.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(identitySessionStoreProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ZenListScreen(
        resource: _resource,
        client: client,
        messages: adminMessages,
        onEdit: (id) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ZenFormScreen(
                resource: _resource,
                client: client,
                messages: adminMessages,
                id: id,
                onSuccess: () => Navigator.of(context).pop(),
              ),
            ),
          );
        },
        onDelete: (id) {
          showDialog<bool>(
            context: context,
            builder: (_) => ZenDeleteDialog(
              client: client,
              resourceName: _resource.resourceName,
              id: id,
              messages: adminMessages,
            ),
          );
        },
        onCreate: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ZenFormScreen(
                resource: _resource,
                client: client,
                messages: adminMessages,
                onSuccess: () => Navigator.of(context).pop(),
              ),
            ),
          );
        },
      ),
    );
  }
}
