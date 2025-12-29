import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart' hide IdentityMessages;
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_ui_identity/dartzen_ui_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIdentityRepository extends Mock implements IdentityRepository {}

class MockLocalizationService extends Mock implements ZenLocalizationService {}

void main() {
  late MockIdentityRepository repository;
  late MockLocalizationService localizationService;
  late IdentityMessages messages;

  setUp(() {
    repository = MockIdentityRepository();
    localizationService = MockLocalizationService();
    messages = IdentityMessages(localizationService, 'en');

    // Default mocks for messages
    when(
      () => localizationService.translate(
        any(),
        language: any(named: 'language'),
        module: any(named: 'module'),
        params: any(named: 'params'),
      ),
    ).thenAnswer((invocation) => invocation.positionalArguments[0] as String);

    when(
      () => repository.getCurrentIdentity(),
    ).thenAnswer((_) async => const ZenResult.ok(null));
  });

  Widget createTestWidget({IdentityMessages? customMessages}) {
    return ProviderScope(
      overrides: [identityRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: ThemeData(extensions: [IdentityThemeExtension.fallback()]),
        home: LoginScreen(
          messages: customMessages ?? messages,
          onLoginSuccess: () {},
        ),
      ),
    );
  }

  testWidgets('LoginScreen shows title and fields', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('login.title'), findsOneWidget);
    expect(find.byType(IdentityTextField), findsNWidgets(2));
    expect(find.byType(IdentityButton), findsNWidgets(3));
  });

  testWidgets('Validation shows errors when fields are empty', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('login.button'));
    await tester.pump();

    expect(find.text('validation.required'), findsWidgets);
  });

  testWidgets('Successful login calls onLoginSuccess', (tester) async {
    bool loginCalled = false;
    final model = IdentityContract(
      id: 'user-1',
      lifecycle: const IdentityLifecycleContract(state: 'active'),
      authority: const AuthorityContract(roles: ['USER']),
      createdAt: ZenTimestamp.now().millisecondsSinceEpoch,
    );

    when(
      () => repository.loginWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => ZenResult.ok(model));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: ThemeData(extensions: [IdentityThemeExtension.fallback()]),
          home: LoginScreen(
            messages: messages,
            onLoginSuccess: () => loginCalled = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(IdentityTextField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(IdentityTextField).last, 'password');
    await tester.tap(find.text('login.button'));
    await tester.pumpAndSettle();

    expect(loginCalled, isTrue);
  });
}
