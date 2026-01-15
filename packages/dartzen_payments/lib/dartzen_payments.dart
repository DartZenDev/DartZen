/// DartZen Payments — payment domain and provider contracts.
///
/// Exposes payment domain types and the abstract [PaymentsService].
/// Provider implementations are kept internal to preserve explicit configuration
/// and ownership boundaries.
library;

import 'src/payments_service.dart';

export 'src/payment.dart';
export 'src/payment_error.dart';
export 'src/payment_intent.dart';
export 'src/payment_status.dart';
export 'src/payments_service.dart';
