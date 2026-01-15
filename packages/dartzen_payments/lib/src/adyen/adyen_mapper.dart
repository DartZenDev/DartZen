import '../payment.dart';
import 'adyen_models.dart';

/// Maps Adyen models to domain payments.
class AdyenPaymentMapper {
  /// Creates an Adyen mapper.
  const AdyenPaymentMapper();

  /// Converts an Adyen payload into a domain [Payment].
  Payment toDomain(AdyenPaymentModel model) => Payment(
    id: model.paymentId,
    intentId: model.intentId.isEmpty ? model.paymentId : model.intentId,
    provider: 'adyen',
    amountMinor: model.amountMinor,
    currency: model.currency,
    status: adyenStatusToDomain(model.resultCode),
    providerReference: model.pspReference,
    createdAt: model.createdAt,
  );
}
