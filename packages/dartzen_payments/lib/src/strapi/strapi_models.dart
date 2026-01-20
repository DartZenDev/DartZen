import 'package:meta/meta.dart';

import '../payment_status.dart';

/// Internal: Strapi model types. Not part of public API.
@internal
class StrapiPaymentModel {
  /// Provider-issued payment identifier.
  final String id;

  /// Correlated intent identifier.
  final String intentId;

  /// Optional provider reference for reconciliation.
  final String? providerReference;

  /// Payment lifecycle status string.
  final String status;

  /// Amount in minor units.
  final int amountMinor;

  /// ISO 4217 currency.
  final String currency;

  /// Creation timestamp from provider or current time.
  final DateTime createdAt;

  /// Creates a Strapi payment model from parsed JSON.
  const StrapiPaymentModel({
    required this.id,
    required this.intentId,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
    this.providerReference,
  });

  /// Parses Strapi JSON into a strongly typed model.
  factory StrapiPaymentModel.fromJson(Map<String, dynamic> json) =>
      StrapiPaymentModel(
        id: json['id'] as String,
        intentId:
            json['intent_id'] as String? ??
            json['intentId'] as String? ??
            json['id'] as String,
        status: json['status'] as String,
        amountMinor: json['amount_minor'] as int? ?? json['amountMinor'] as int,
        currency: json['currency'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now().toUtc(),
        providerReference:
            json['provider_reference'] as String? ??
            json['providerReference'] as String?,
      );
}

/// Maps Strapi textual status to domain [PaymentStatus].
PaymentStatus strapiStatusToDomain(String status) {
  switch (status) {
    case 'pending':
      return PaymentStatus.pending;
    case 'initiated':
    case 'processing':
      return PaymentStatus.initiated;
    case 'authorized':
      return PaymentStatus.confirmed;
    case 'succeeded':
    case 'completed':
      return PaymentStatus.completed;
    case 'refunded':
      return PaymentStatus.refunded;
    case 'failed':
    default:
      return PaymentStatus.failed;
  }
}
