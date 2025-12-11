/// The core layer for the DartZen ecosystem.
///
/// This library provides universal types and utilities that are shared across
/// client and server boundaries, ensuring a consistent and robust architecture.
///
/// Use [ZenResult] for functional error handling, [BaseResponse] for API contracts,
/// and core value objects like [ZenTimestamp] and [EmailAddress] for domain modeling.
library dartzen_core;

export 'src/dartzen_constants.dart';
export 'src/response/base_response.dart';
export 'src/result/zen_error.dart';
export 'src/result/zen_result.dart';
export 'src/utils/zen_guard.dart';
export 'src/utils/zen_try.dart';
export 'src/value_objects/common_types.dart';
export 'src/value_objects/ids.dart';
