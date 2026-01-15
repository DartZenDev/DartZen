import '../payment_status.dart';

/// Raw Adyen payment payload.
class AdyenPaymentModel {
  /// Provider-issued payment identifier.
  final String paymentId;

  /// Intent reference received from client or echoed by provider.
  final String intentId;

  /// Optional PSP reference for reconciliation.
  final String? pspReference;

  /// Result code string returned by Adyen.
  final String resultCode;

  /// Amount in minor units.
  final int amountMinor;

  /// ISO 4217 currency.
  final String currency;

  /// Creation timestamp from provider or current time.
  final DateTime createdAt;

  /// Creates an Adyen payment model from parsed JSON.
  const AdyenPaymentModel({
    required this.paymentId,
    required this.intentId,
    required this.resultCode,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
    this.pspReference,
  });

  /// Parses Adyen JSON into a strongly typed model.
  factory AdyenPaymentModel.fromJson(
    Map<String, dynamic> json,
  ) => AdyenPaymentModel(
    paymentId: json['paymentId'] as String? ?? json['id'] as String,
    intentId: json['intentId'] as String? ?? json['reference'] as String? ?? '',
    resultCode:
        json['resultCode'] as String? ?? json['status'] as String? ?? 'Error',
    amountMinor:
        (json['amount'] as Map?)?['value'] as int? ??
        json['amount_minor'] as int? ??
        json['amountMinor'] as int,
    currency:
        (json['amount'] as Map?)?['currency'] as String? ??
        json['currency'] as String? ??
        'USD',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now().toUtc(),
    pspReference: json['pspReference'] as String?,
  );
}

/// Maps Adyen result codes to domain [PaymentStatus].
PaymentStatus adyenStatusToDomain(String resultCode) {
  switch (resultCode) {
    case 'Received':
    case 'Pending':
      return PaymentStatus.pending;
    case 'Authorised':
    case 'Authorized':
      return PaymentStatus.confirmed;
    case 'PresentToShopper':
    case 'RedirectShopper':
      return PaymentStatus.initiated;
    case 'Captured':
    case 'SentForSettle':
    case 'Settled':
      return PaymentStatus.completed;
    case 'Refunded':
    case 'PartiallyRefunded':
      return PaymentStatus.refunded;
    case 'Refused':
    case 'Cancelled':
    case 'Error':
    default:
      return PaymentStatus.failed;
  }
}
