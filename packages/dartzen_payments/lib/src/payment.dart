import 'package:meta/meta.dart';

import 'payment_status.dart';

/// Represents a concrete payment tracked in DartZen.
@immutable
final class Payment {
  /// Unique payment identifier (provider-issued or internal).
  final String id;

  /// Correlated intent identifier.
  final String intentId;

  /// Payment provider name (e.g. 'strapi', 'adyen').
  final String provider;

  /// Amount in minor units.
  final int amountMinor;

  /// ISO 4217 currency.
  final String currency;

  /// Current lifecycle status.
  final PaymentStatus status;

  /// Optional provider-specific reference (e.g. PSP reference).
  final String? providerReference;

  /// UTC timestamp of creation.
  final DateTime createdAt;

  /// Creates a payment domain entity.
  const Payment({
    required this.id,
    required this.intentId,
    required this.provider,
    required this.amountMinor,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.providerReference,
  });

  /// Serialize to JSON for storage or telemetry payloads.
  Map<String, dynamic> toJson() => {
    'id': id,
    'intentId': intentId,
    'provider': provider,
    'amountMinor': amountMinor,
    'currency': currency,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    if (providerReference != null) 'providerReference': providerReference,
  };

  /// Rehydrate from JSON (trusted sources only).
  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    intentId: json['intentId'] as String,
    provider: json['provider'] as String,
    amountMinor: json['amountMinor'] as int,
    currency: json['currency'] as String,
    status: PaymentStatus.values.firstWhere(
      (s) => s.name == json['status'] as String,
      orElse: () => PaymentStatus.failed,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    providerReference: json['providerReference'] as String?,
  );
}
