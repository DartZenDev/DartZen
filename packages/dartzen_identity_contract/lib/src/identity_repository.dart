import 'package:dartzen_core/dartzen_core.dart';

import 'models/identity.dart';

/// Contract for identity operations required by clients (UI, CLI, etc.).
///
/// This interface allows subscribers to remain independent of the specific authentication implementation.
abstract interface class IdentityRepository {
  /// Signs in a user with email and password.
  Future<ZenResult<IdentityModel>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user with email and password.
  Future<ZenResult<IdentityModel>> registerWithEmail({
    required String email,
    required String password,
  });

  /// Initiates password restoration for the given email.
  Future<ZenResult<void>> restorePassword({required String email});

  /// Logs out the current user.
  Future<ZenResult<void>> logout();

  /// Retrieves the current authenticated identity.
  Future<ZenResult<IdentityModel?>> getCurrentIdentity();
}
