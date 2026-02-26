import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_client.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_field.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_permissions.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_resource.dart';
import 'package:dartzen_ui_admin/src/l10n/zen_admin_messages.dart';
import 'package:dartzen_ui_admin/src/screens/zen_form_screen.dart';
import 'package:dartzen_ui_admin/src/theme/admin_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_localization.dart';

class _MockClient extends Mock implements ZenAdminClient {}

void main() {
  late _MockClient client;
  late ZenAdminMessages messages;
  late ZenAdminResource<Map<String, dynamic>> resource;

  setUp(() {
    client = _MockClient();
    messages = ZenAdminMessages(
      FakeLocalization({
        'list.title': 'List',
        'create.title': 'Create',
        'edit.title': 'Edit',
        'delete.confirmation': 'Are you sure?',
        'save': 'Save',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'required.field': 'Required',
        'loading': 'Loading...',
        'no.items': 'No items found',
        'edit': 'Edit',
        'confirm.delete': 'Confirm Delete',
        'actions': 'Actions',
      }),
      'en',
    );
    resource = ZenAdminResource<Map<String, dynamic>>(
      resourceName: 'users',
      displayName: 'Users',
      fields: const [
        ZenAdminField(
          name: 'name',
          label: 'Name',
          editable: true,
          required: true,
        ),
        ZenAdminField(name: 'email', label: 'Email', editable: true),
      ],
      permissions: const ZenAdminPermissions(canRead: true, canWrite: true),
    );
  });

  Widget buildSubject({String? id, VoidCallback? onSuccess}) {
    return MaterialApp(
      theme: ThemeData(extensions: [AdminThemeExtension.fallback()]),
      home: ZenFormScreen(
        resource: resource,
        client: client,
        messages: messages,
        id: id,
        onSuccess: onSuccess,
      ),
    );
  }

  group('create mode', () {
    testWidgets('shows create title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Create'), findsOneWidget);
    });

    testWidgets('shows editable fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('calls create on submit', (tester) async {
      when(() => client.create(any(), any())).thenAnswer((_) async {});

      bool successCalled = false;
      await tester.pumpWidget(
        buildSubject(onSuccess: () => successCalled = true),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@test.com',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => client.create('users', {
          'name': 'Alice',
          'email': 'alice@test.com',
        }),
      ).called(1);
      expect(successCalled, isTrue);
    });

    testWidgets('shows snackbar on create error', (tester) async {
      when(
        () => client.create(any(), any()),
      ).thenThrow(const ZenTransportException('Conflict'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Alice',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Conflict'), findsOneWidget);
    });

    testWidgets('cancel button pops the screen', (tester) async {
      // Push form screen on top of a placeholder so maybePop has
      // somewhere to go.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AdminThemeExtension.fallback()]),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ZenFormScreen(
                    resource: resource,
                    client: client,
                    messages: messages,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The form screen should be visible.
      expect(find.textContaining('Create'), findsAtLeast(1));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Form should be gone, back to the initial screen.
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('edit mode', () {
    testWidgets('shows edit title and loads record', (tester) async {
      when(
        () => client.fetchById(any(), any()),
      ).thenAnswer((_) async => {'name': 'Bob', 'email': 'bob@test.com'});

      await tester.pumpWidget(buildSubject(id: '1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Edit'), findsOneWidget);

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Name'),
      );
      expect(nameField.controller?.text, 'Bob');
    });

    testWidgets('calls update on submit in edit mode', (tester) async {
      when(
        () => client.fetchById(any(), any()),
      ).thenAnswer((_) async => {'name': 'Bob', 'email': 'bob@test.com'});
      when(() => client.update(any(), any(), any())).thenAnswer((_) async {});

      bool successCalled = false;
      await tester.pumpWidget(
        buildSubject(id: '1', onSuccess: () => successCalled = true),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Updated',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => client.update('users', '1', any())).called(1);
      expect(successCalled, isTrue);
    });

    testWidgets('shows error when fetch fails', (tester) async {
      when(
        () => client.fetchById(any(), any()),
      ).thenThrow(const ZenTransportException('Not found'));

      await tester.pumpWidget(buildSubject(id: '99'));
      await tester.pumpAndSettle();

      expect(find.text('Not found'), findsOneWidget);
    });
  });
}
