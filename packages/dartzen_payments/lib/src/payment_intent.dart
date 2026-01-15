import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

/// Represents a client-supplied intent to perform a payment.
@immutable
final class PaymentIntent {
  /// Unique identifier for the intent (client-side correlation).
  final String id;

  /// Amount in minor units (e.g. cents).
  final int amountMinor;

  /// ISO 4217 currency code (uppercase).
  final String currency;

  /// Idempotency key used to guarantee safe retries across providers.
  final String idempotencyKey;

  /// Optional human-readable description for statements or receipts.
  final String? description;

  /// Optional arbitrary metadata forwarded to providers when supported.
  final Map<String, String>? metadata;

  const PaymentIntent._({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.idempotencyKey,
    this.description,
    this.metadata,
  });

  /// Creates and validates a [PaymentIntent].
  static ZenResult<PaymentIntent> create({
    required String id,
    required int amountMinor,
    required String currency,
    required String idempotencyKey,
    String? description,
    Map<String, String>? metadata,
  }) {
    if (id.trim().isEmpty) {
      return const ZenResult.err(
        ZenValidationError('PaymentIntent id is required'),
      );
    }
    if (amountMinor <= 0) {
      return const ZenResult.err(
        ZenValidationError('Amount must be greater than zero'),
      );
    }
    if (currency.trim().length != 3 || currency.toUpperCase() != currency) {
      return const ZenResult.err(
        ZenValidationError('Currency must be ISO 4217 uppercase 3 letters'),
      );
    }
    if (idempotencyKey.trim().isEmpty) {
      return const ZenResult.err(
        ZenValidationError('Idempotency key is required for payment intent'),
      );
    }

    return ZenResult.ok(
      PaymentIntent._(
        id: id,
        amountMinor: amountMinor,
        currency: currency,
        idempotencyKey: idempotencyKey,
        description: description,
        metadata: metadata == null ? null : Map.unmodifiable(metadata),
      ),
    );
  }

  /// Serialize to JSON for providers or storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'amountMinor': amountMinor,
    'currency': currency,
    'idempotencyKey': idempotencyKey,
    if (description != null) 'description': description,
    if (metadata != null) 'metadata': metadata,
  };

  /// Reconstruct from JSON (trusted source only).
  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent._(
    id: json['id'] as String,
    amountMinor: json['amountMinor'] as int,
    currency: json['currency'] as String,
    idempotencyKey: json['idempotencyKey'] as String,
    description: json['description'] as String?,
    metadata: (json['metadata'] as Map?)?.cast<String, String>(),
  );
}
