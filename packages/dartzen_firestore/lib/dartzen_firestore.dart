/// Firestore utility toolkit for DartZen packages.
///
/// This package provides low-level Firestore primitives:
/// - Connection management (production vs emulator)
/// - Type converters (Timestamp ↔ ZenTimestamp, claims normalization)
/// - Batch and transaction helpers with ZenResult support
/// - Error normalization (Firestore exceptions → ZenError)
/// - Optional telemetry hooks
///
/// This package is domain-agnostic and does NOT contain:
/// - Domain logic, repositories, or DTOs
/// - Query builders or schema validation
/// - Caching, authentication, or migrations
library;

export 'src/connection/firestore_config.dart';
export 'src/connection/firestore_connection.dart';
export 'src/converters/firestore_converters.dart';
export 'src/errors/firestore_error_codes.dart';
export 'src/errors/firestore_error_mapper.dart';
export 'src/l10n/firestore_messages.dart';
export 'src/operations/firestore_batch.dart';
export 'src/operations/firestore_transaction.dart';
export 'src/telemetry/firestore_telemetry.dart';
