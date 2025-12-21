import 'package:dartzen_core/dartzen_core.dart';

/// Base class for all identity-related failures.
sealed class IdentityContractFailure extends ZenError {
  /// A machine-readable error code.
  final String code;

  const IdentityContractFailure(super.message, {required this.code});

  /// The error code associated with this failure.
  String? get errorCode => code;
}

/// Represents a failure related to identity operations (creation, lookup, etc.).
final class IdentityFailure extends IdentityContractFailure {
  /// Creates an [IdentityFailure].
  const IdentityFailure(super.message, {required super.code});

  /// Identity not found.
  factory IdentityFailure.notFound(String id) =>
      IdentityFailure("Identity '$id' not found", code: 'IDENTITY_NOT_FOUND');

  /// Identity already exists.
  factory IdentityFailure.alreadyExists(String id) => IdentityFailure(
    "Identity '$id' already exists",
    code: 'IDENTITY_ALREADY_EXISTS',
  );

  /// Identity is deactivated.
  factory IdentityFailure.deactivated(String id) => IdentityFailure(
    "Identity '$id' is deactivated",
    code: 'IDENTITY_DEACTIVATED',
  );
}

/// Represents a failure related to authority and permissions.
final class AuthorityFailure extends IdentityContractFailure {
  /// Creates an [AuthorityFailure].
  const AuthorityFailure(super.message, {required super.code});

  /// Permission denied.
  factory AuthorityFailure.permissionDenied(String resource, String action) =>
      AuthorityFailure(
        'Permission denied for $action on $resource',
        code: 'PERMISSION_DENIED',
      );

  /// Role not assigned.
  factory AuthorityFailure.roleNotAssigned(String roleId) => AuthorityFailure(
    "Role '$roleId' not assigned",
    code: 'ROLE_NOT_ASSIGNED',
  );
}

/// Represents a structural validation failure in contract objects.
final class ValidationFailure extends IdentityContractFailure {
  /// Creates a [ValidationFailure].
  const ValidationFailure(super.message, {required super.code});

  /// Invalid format.
  factory ValidationFailure.invalidFormat(String field, String reason) =>
      ValidationFailure(
        "Invalid format for field '$field': $reason",
        code: 'INVALID_FORMAT',
      );

  /// Missing required field.
  factory ValidationFailure.missingField(String field) => ValidationFailure(
    "Missing required field '$field'",
    code: 'MISSING_FIELD',
  );
}
