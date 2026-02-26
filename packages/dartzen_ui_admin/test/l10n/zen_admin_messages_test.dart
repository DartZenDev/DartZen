import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_ui_admin/src/l10n/zen_admin_messages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_localization.dart';

void main() {
  late ZenAdminMessages messages;

  setUp(() {
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
        'no.items': 'No items',
        'edit': 'Edit',
        'confirm.delete': 'Confirm Delete',
        'actions': 'Actions',
        'error.unauthorized': 'Unauthorized',
        'error.not_found': 'Not found',
        'error.validation': 'Validation error',
        'error.conflict': 'Conflict',
        'error.unknown': 'Unknown error',
        'previous.page': 'Previous page',
        'next.page': 'Next page',
      }),
      'en',
    );
  });

  test('module is "admin"', () {
    expect(ZenAdminMessages.module, 'admin');
  });

  test('listTitle returns translated value', () {
    expect(messages.listTitle, 'List');
  });

  test('createTitle returns translated value', () {
    expect(messages.createTitle, 'Create');
  });

  test('editTitle returns translated value', () {
    expect(messages.editTitle, 'Edit');
  });

  test('deleteConfirmation returns translated value', () {
    expect(messages.deleteConfirmation, 'Are you sure?');
  });

  test('save returns translated value', () {
    expect(messages.save, 'Save');
  });

  test('cancel returns translated value', () {
    expect(messages.cancel, 'Cancel');
  });

  test('delete returns translated value', () {
    expect(messages.delete, 'Delete');
  });

  test('requiredField returns translated value', () {
    expect(messages.requiredField, 'Required');
  });

  test('loading returns translated value', () {
    expect(messages.loading, 'Loading...');
  });

  test('noItems returns translated value', () {
    expect(messages.noItems, 'No items');
  });

  test('edit returns translated value', () {
    expect(messages.edit, 'Edit');
  });

  test('confirmDelete returns translated value', () {
    expect(messages.confirmDelete, 'Confirm Delete');
  });

  test('actions returns translated value', () {
    expect(messages.actions, 'Actions');
  });

  test('previousPage returns translated value', () {
    expect(messages.previousPage, 'Previous page');
  });

  test('nextPage returns translated value', () {
    expect(messages.nextPage, 'Next page');
  });

  group('error mapping', () {
    test('maps ZenUnauthorizedError', () {
      expect(
        messages.error(const ZenUnauthorizedError('test')),
        'Unauthorized',
      );
    });

    test('maps ZenNotFoundError', () {
      expect(messages.error(const ZenNotFoundError('test')), 'Not found');
    });

    test('maps ZenValidationError', () {
      expect(
        messages.error(const ZenValidationError('test')),
        'Validation error',
      );
    });

    test('maps ZenConflictError', () {
      expect(messages.error(const ZenConflictError('test')), 'Conflict');
    });

    test('maps ZenUnknownError to unknown', () {
      expect(messages.error(const ZenUnknownError('test')), 'Unknown error');
    });
  });
}
