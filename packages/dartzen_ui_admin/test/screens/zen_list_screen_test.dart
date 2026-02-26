import 'dart:async';

import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_client.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_field.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_page.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_permissions.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_query.dart';
import 'package:dartzen_ui_admin/src/admin/zen_admin_resource.dart';
import 'package:dartzen_ui_admin/src/l10n/zen_admin_messages.dart';
import 'package:dartzen_ui_admin/src/screens/zen_list_screen.dart';
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

  setUpAll(() {
    registerFallbackValue(const ZenAdminQuery());
  });

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
        'previous.page': 'Previous page',
        'next.page': 'Next page',
      }),
      'en',
    );
    resource = ZenAdminResource<Map<String, dynamic>>(
      resourceName: 'users',
      displayName: 'Users',
      fields: const [
        ZenAdminField(name: 'id', label: 'ID'),
        ZenAdminField(name: 'name', label: 'Name'),
      ],
      permissions: const ZenAdminPermissions(
        canRead: true,
        canWrite: true,
        canDelete: true,
      ),
    );
  });

  Widget buildSubject({
    ValueChanged<String>? onEdit,
    ValueChanged<String>? onDelete,
    VoidCallback? onCreate,
    ZenAdminResource<Map<String, dynamic>>? overrideResource,
  }) {
    return MaterialApp(
      theme: ThemeData(extensions: [AdminThemeExtension.fallback()]),
      home: ZenListScreen(
        resource: overrideResource ?? resource,
        client: client,
        messages: messages,
        onEdit: onEdit,
        onDelete: onDelete,
        onCreate: onCreate,
      ),
    );
  }

  void stubQuery(ZenAdminPage<Map<String, dynamic>> page) {
    when(() => client.query(any(), any())).thenAnswer((_) async => page);
  }

  void stubQueryError(String message) {
    when(
      () => client.query(any(), any()),
    ).thenThrow(ZenTransportException(message));
  }

  testWidgets('shows loading indicator initially', (tester) async {
    final completer = Completer<ZenAdminPage<Map<String, dynamic>>>();
    when(() => client.query(any(), any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);

    completer.complete(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows no items message for empty page', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No items found'), findsOneWidget);
  });

  testWidgets('shows data table with records', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '1', 'name': 'Alice'},
          {'id': '2', 'name': 'Bob'},
        ],
        total: 2,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('shows localized Actions column header', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '1', 'name': 'Alice'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsOneWidget);
  });

  testWidgets('shows error message on transport failure', (tester) async {
    stubQueryError('Server error');

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
  });

  testWidgets('fab visible when canWrite is true', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject(onCreate: () {}));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('fab hidden when canWrite is false', (tester) async {
    final readOnly = ZenAdminResource<Map<String, dynamic>>(
      resourceName: 'users',
      displayName: 'Users',
      fields: const [ZenAdminField(name: 'id', label: 'ID')],
      permissions: const ZenAdminPermissions(canRead: true),
    );

    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject(overrideResource: readOnly));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('edit icon calls onEdit with record id', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '42', 'name': 'Alice'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    String? editedId;
    await tester.pumpWidget(buildSubject(onEdit: (id) => editedId = id));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(editedId, '42');
  });

  testWidgets('uses custom idFieldName for edit', (tester) async {
    final customId = ZenAdminResource<Map<String, dynamic>>(
      resourceName: 'users',
      displayName: 'Users',
      fields: const [
        ZenAdminField(name: 'userId', label: 'User ID'),
        ZenAdminField(name: 'name', label: 'Name'),
      ],
      permissions: const ZenAdminPermissions(
        canRead: true,
        canWrite: true,
        canDelete: true,
      ),
      idFieldName: 'userId',
    );

    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'userId': '99', 'name': 'Carol'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    String? editedId;
    await tester.pumpWidget(
      buildSubject(overrideResource: customId, onEdit: (id) => editedId = id),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(editedId, '99');
  });

  testWidgets('delete icon calls onDelete with record id', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '42', 'name': 'Alice'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    String? deletedId;
    await tester.pumpWidget(buildSubject(onDelete: (id) => deletedId = id));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(deletedId, '42');
  });

  testWidgets('pagination shows range and navigates forward', (tester) async {
    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(20, (i) => {'id': '$i', 'name': 'User $i'}),
        total: 25,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('1–20 of 25'), findsOneWidget);

    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(
          5,
          (i) => {'id': '${20 + i}', 'name': 'User ${20 + i}'},
        ),
        total: 25,
        offset: 20,
        limit: 20,
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.textContaining('21–25 of 25'), findsOneWidget);
  });

  testWidgets('chevron_left navigates to previous page', (tester) async {
    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(20, (i) => {'id': '$i', 'name': 'User $i'}),
        total: 25,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Move to page 2.
    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(
          5,
          (i) => {'id': '${20 + i}', 'name': 'User ${20 + i}'},
        ),
        total: 25,
        offset: 20,
        limit: 20,
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.textContaining('21–25 of 25'), findsOneWidget);

    // Go back to page 1.
    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(20, (i) => {'id': '$i', 'name': 'User $i'}),
        total: 25,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.textContaining('1–20 of 25'), findsOneWidget);
  });

  testWidgets('edit icon has semantic label', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '1', 'name': 'Alice'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final semantics = find.ancestor(
      of: find.byIcon(Icons.edit),
      matching: find.byType(Semantics),
    );
    expect(semantics, findsWidgets);
  });

  testWidgets('delete icon has semantic label', (tester) async {
    stubQuery(
      const ZenAdminPage<Map<String, dynamic>>(
        items: [
          {'id': '1', 'name': 'Alice'},
        ],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final semantics = find.ancestor(
      of: find.byIcon(Icons.delete),
      matching: find.byType(Semantics),
    );
    expect(semantics, findsWidgets);
  });

  testWidgets('pagination buttons have semantic labels', (tester) async {
    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(20, (i) => {'id': '$i', 'name': 'User $i'}),
        total: 25,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Previous page button has Semantics wrapper.
    final prevSemantics = find.ancestor(
      of: find.byIcon(Icons.chevron_left),
      matching: find.byType(Semantics),
    );
    expect(prevSemantics, findsWidgets);

    // Next page button has Semantics wrapper.
    final nextSemantics = find.ancestor(
      of: find.byIcon(Icons.chevron_right),
      matching: find.byType(Semantics),
    );
    expect(nextSemantics, findsWidgets);
  });

  testWidgets('pagination buttons have tooltips', (tester) async {
    stubQuery(
      ZenAdminPage<Map<String, dynamic>>(
        items: List.generate(20, (i) => {'id': '$i', 'name': 'User $i'}),
        total: 25,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final prevButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    expect(prevButton.tooltip, 'Previous page');

    final nextButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(nextButton.tooltip, 'Next page');
  });
}
