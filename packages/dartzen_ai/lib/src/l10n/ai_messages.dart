import 'package:dartzen_localization/dartzen_localization.dart';

/// Access to localized messages for the AI package.
///
/// Wraps [ZenLocalizationService] to provide strongly-typed access
/// to AI-related messages without exposing raw strings.
class AIMessages {
  /// The localization service.
  final ZenLocalizationService _service;

  /// The current language code.
  final String _language;

  /// Creates an [AIMessages] wrapper.
  const AIMessages(this._service, this._language);

  /// Helper to get the module name.
  static const String module = 'ai';

  String _t(String key, [Map<String, dynamic> params = const {}]) => _service
      .translate(key, language: _language, module: module, params: params);

  /// Budget exceeded error message.
  String budgetExceeded() => _t('ai.budget_exceeded');

  /// Quota exceeded error message.
  String quotaExceeded() => _t('ai.quota_exceeded');

  /// Invalid request error message.
  String invalidRequest() => _t('ai.invalid_request');

  /// Service unavailable error message.
  String serviceUnavailable() => _t('ai.service_unavailable');

  /// Authentication failed error message.
  String authenticationFailed() => _t('ai.authentication_failed');

  /// Request cancelled message.
  String requestCancelled() => _t('ai.request_cancelled');
}
