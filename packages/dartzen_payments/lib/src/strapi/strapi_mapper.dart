import 'package:meta/meta.dart';

import '../payment.dart';
import 'strapi_models.dart';

/// Internal: Strapi mapper. Not part of public API.
@internal
class StrapiPaymentMapper {
  /// Creates a Strapi mapper.
  const StrapiPaymentMapper();

  /// Converts a Strapi payload into a domain [Payment].
  Payment toDomain({required StrapiPaymentModel model}) => Payment(
    id: model.id,
    intentId: model.intentId,
    provider: 'strapi',
    amountMinor: model.amountMinor,
    currency: model.currency,
    status: strapiStatusToDomain(model.status),
    providerReference: model.providerReference,
    createdAt: model.createdAt,
  );
}
