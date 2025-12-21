import 'package:dartzen_core/dartzen_core.dart';

/// Represents a failure in the infrastructure layer (e.g. database, network).
class ZenInfrastructureError extends ZenError {
  /// Creates a [ZenInfrastructureError].
  ZenInfrastructureError(
    super.message, {
    Object? originalError,
    super.stackTrace,
  }) : super(
         internalData: originalError != null
             ? {'originalError': originalError}
             : null,
       );
}
