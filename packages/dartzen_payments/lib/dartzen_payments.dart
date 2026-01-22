/// DartZen Payments — payment domain and provider contracts.
///
/// Exposes payment domain types and the abstract [PaymentsService].
/// Provider implementations are kept internal to preserve explicit configuration
/// and ownership boundaries.
library;

import 'src/payments_service.dart' show PaymentsService;

export 'src/executor.dart';
export 'src/local_executor.dart';
export 'src/missing_descriptor_exception.dart';
// Public API: domain types and executor-first runtime primitives.
export 'src/payment.dart';
// Descriptor / Policy / Executor primitives
export 'src/payment_descriptor.dart';
export 'src/payment_error.dart';
export 'src/payment_intent.dart';
export 'src/payment_policy.dart';
export 'src/payment_result.dart';
export 'src/payment_status.dart';
export 'src/test_executor.dart';

// Note: Provider adapters and concrete services (e.g., Adyen/Strapi)
// live under `src/` and are intentionally not exported as part of the
// public API. Direct provider access is forbidden; use an `Executor`.
