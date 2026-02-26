import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_client.dart';
import 'package:dartzen_ui_admin/src/l10n/zen_admin_messages.dart';
import 'package:dartzen_ui_admin/src/screens/zen_delete_dialog.dart';
import 'package:dartzen_ui_admin/src/theme/admin_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_localization.dart';

class _MockClient extends Mock implements ZenAdminClient {}

void main() {
  late _MockClient client;
  late ZenAdminMessages messages;

  setUp(() {
    client = _MockClient();
    messages = ZenAdminMessages(
      FakeLocalization({
        'confirm.delete': 'Confirm Delete',
        'delete.confirmation': 'Are you sure you want to delete?',
        'cancel': 'Cancel',
        'delete': 'Delete',
      }),
      'en',
    );
  });

  Future<bool?> showDeleteDialog(
    WidgetTester tester, {
    VoidCallback? onSuccess,
    AdminThemeExtension? themeExtension,
  }) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [themeExtension ?? AdminThemeExtension.fallback()],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => ZenDeleteDialog(
                      client: client,
                      resourceName: 'users',
                      id: '42',
                      messages: messages,
                      onSuccess: onSuccess,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    return result;
  }

  testWidgets('shows confirmation title and message', (tester) async {
    await showDeleteDialog(tester);

    expect(find.text('Confirm Delete'), findsOneWidget);
    expect(find.text('Are you sure you want to delete?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('cancel pops false', (tester) async {
    await showDeleteDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Delete'), findsNothing);
  });

  testWidgets('delete calls client and pops true', (tester) async {
    when(() => client.delete(any(), any())).thenAnswer((_) async {});

    bool successCalled = false;
    await showDeleteDialog(tester, onSuccess: () => successCalled = true);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => client.delete('users', '42')).called(1);
    expect(successCalled, isTrue);
    expect(find.text('Confirm Delete'), findsNothing);
  });

  testWidgets('shows snackbar on delete error', (tester) async {
    when(
      () => client.delete(any(), any()),
    ).thenThrow(const ZenTransportException('Forbidden'));

    await showDeleteDialog(tester);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Forbidden'), findsOneWidget);
  });

  testWidgets('uses AdminThemeExtension colors', (tester) async {
    final customTheme = AdminThemeExtension.fallback().copyWith(
      dangerColor: const Color(0xFFFF00FF),
      surfaceColor: const Color(0xFF00FF00),
    );

    await showDeleteDialog(tester, themeExtension: customTheme);

    // Find the delete ElevatedButton.
    final deleteButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Delete'),
    );

    final resolved = deleteButton.style?.backgroundColor?.resolve({});
    expect(resolved, const Color(0xFFFF00FF));
  });
}
