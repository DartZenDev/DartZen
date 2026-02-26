import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';

/// Strongly-typed accessor for admin module localization messages.
///
/// Wraps [ZenLocalizationService] so that UI code never calls
/// the localization service directly.
class ZenAdminMessages {
  final ZenLocalizationService _service;
  final String _language;

  /// Creates a [ZenAdminMessages] wrapper.
  const ZenAdminMessages(this._service, this._language);

  /// The localization module identifier.
  static const String module = 'admin';

  String _t(String key, [Map<String, dynamic> params = const {}]) {
    return _service.translate(
      key,
      language: _language,
      module: module,
      params: params,
    );
  }

  /// Title for the list screen.
  String get listTitle => _t('list.title');

  /// Title for the create screen.
  String get createTitle => _t('create.title');

  /// Title for the edit screen.
  String get editTitle => _t('edit.title');

  /// Confirmation message for delete actions.
  String get deleteConfirmation => _t('delete.confirmation');

  /// Label for the save button.
  String get save => _t('save');

  /// Label for the cancel button.
  String get cancel => _t('cancel');

  /// Label for the delete button.
  String get delete => _t('delete');

  /// Validation message for required fields.
  String get requiredField => _t('required.field');

  /// Loading indicator text.
  String get loading => _t('loading');

  /// Message shown when no items are found.
  String get noItems => _t('no.items');

  /// Label for the edit action.
  String get edit => _t('edit');

  /// Title for the delete confirmation dialog.
  String get confirmDelete => _t('confirm.delete');

  /// Label for the actions column header.
  String get actions => _t('actions');

  /// Tooltip / semantic label for the previous-page button.
  String get previousPage => _t('previous.page');

  /// Tooltip / semantic label for the next-page button.
  String get nextPage => _t('next.page');

  /// Maps a [ZenError] to a localized error message.
  String error(ZenError error) {
    if (error is ZenUnauthorizedError) {
      return _t('error.unauthorized');
    }
    if (error is ZenNotFoundError) {
      return _t('error.not_found');
    }
    if (error is ZenValidationError) {
      return _t('error.validation');
    }
    if (error is ZenConflictError) {
      return _t('error.conflict');
    }
    return _t('error.unknown');
  }
}
