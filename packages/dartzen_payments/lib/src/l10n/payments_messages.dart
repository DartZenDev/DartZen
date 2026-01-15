import 'package:dartzen_localization/dartzen_localization.dart';

import '../payment_error.dart';

/// Message accessor for payment-related strings.
class PaymentsMessages {
  final ZenLocalizationService _localization;
  final String _language;

  /// Creates a [PaymentsMessages] accessor.
  const PaymentsMessages(this._localization, this._language);

  /// Localized string for declined payments.
  String declined() => _t('error.declined');

  /// Localized string for insufficient funds.
  String insufficientFunds() => _t('error.insufficient_funds');

  /// Localized string for invalid amount.
  String invalidAmount() => _t('error.invalid_amount');

  /// Localized string for missing payments.
  String notFound() => _t('error.not_found');

  /// Localized string for invalid state transitions.
  String state() => _t('error.state');

  /// Localized string for provider failures.
  String provider() => _t('error.provider');

  /// Localized string for unknown errors.
  String unknown() => _t('error.unknown');

  /// Maps a [PaymentError] to a localized message.
  String error(PaymentError error) {
    if (error is PaymentDeclinedError) return declined();
    if (error is PaymentInsufficientFundsError) return insufficientFunds();
    if (error is PaymentInvalidAmountError) return invalidAmount();
    if (error is PaymentNotFoundError) return notFound();
    if (error is PaymentStateError) return state();
    if (error is PaymentProviderError) return provider();
    return unknown();
  }

  String _t(String key) => _localization.translate(
    'payments.$key',
    language: _language,
    module: 'payments',
  );
}
