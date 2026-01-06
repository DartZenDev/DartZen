import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_ui_identity/src/l10n/identity_messages.dart';
import 'package:dartzen_ui_identity/src/screens/profile_screen.dart';
import 'package:dartzen_ui_identity/src/state/identity_repository.dart';
import 'package:dartzen_ui_identity/src/theme/identity_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IdentityRepository {
  ZenResult<IdentityContract?> current;
  ZenResult<void> logoutResult;
  _FakeRepo({
    ZenResult<IdentityContract?>? current,
    ZenResult<void>? logoutResult,
  }) : current = current ?? const ZenResult.ok(null),
       logoutResult = logoutResult ?? const ZenResult.ok(null);

  @override
  Future<ZenResult<IdentityContract?>> getCurrentIdentity() async => current;

  @override
  Future<ZenResult<IdentityContract>> loginWithEmail({
    required String email,
    required String password,
  }) async => const ZenResult.err(ZenUnknownError('no'));

  @override
  Future<ZenResult<IdentityContract>> registerWithEmail({
    required String email,
    required String password,
  }) async => const ZenResult.err(ZenUnknownError('no'));

  @override
  Future<ZenResult<void>> restorePassword({required String email}) async =>
      const ZenResult.err(ZenUnknownError('no'));

  @override
  Future<ZenResult<void>> logout() async => logoutResult;
}

class _FakeLocalization implements ZenLocalizationService {
  final Map<String, String> _map;
  _FakeLocalization(this._map);
  Map<String, String> getGlobal(String language) => _map;
  Map<String, String> getModule(String module, String language) => _map;
  String translate(
    String key, {
    required String language,
    String? module,
    Map<String, dynamic> params = const {},
  }) => _map[key] ?? key;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const en = 'en';
  final msgs = IdentityMessages(
    _FakeLocalization({
      'profile.title': 'Profile',
      'not.authenticated': 'Not Auth',
      'roles.label': 'Roles',
      'logout.button': 'Logout',
    }),
    en,
  );

  testWidgets('shows not authenticated when no identity', (tester) async {
    final repo = _FakeRepo(current: const ZenResult.ok(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeData(extensions: [IdentityThemeExtension.fallback()]),
          home: ProfileScreen(messages: msgs),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Not Auth'), findsOneWidget);
  });

  testWidgets('displays profile and calls logout callback', (tester) async {
    final contract = IdentityContract(
      id: 'user-1',
      lifecycle: const IdentityLifecycleContract(state: 'active'),
      authority: const AuthorityContract(roles: ['ADMIN']),
      createdAt: ZenTimestamp.now().millisecondsSinceEpoch,
    );

    var called = false;
    final repo = _FakeRepo(
      current: ZenResult.ok(contract),
      logoutResult: const ZenResult.ok(null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeData(extensions: [IdentityThemeExtension.fallback()]),
          home: ProfileScreen(
            messages: msgs,
            onLogoutSuccess: () => called = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('user-1'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });
}
