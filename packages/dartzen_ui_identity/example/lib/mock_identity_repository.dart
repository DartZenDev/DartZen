import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_contract/dartzen_identity_contract.dart'
    as contract;

/// One-time setup to create a fake valid identity
final _mockIdentity = contract.IdentityModel(
  id: const contract.IdentityId('user-123'),
  createdAt: ZenTimestamp.now(),
  authority: const contract.Authority(
    identityId: contract.IdentityId('user-123'),
    roles: [
      contract.Role(id: 'user', name: 'User'),
      contract.Role(id: 'admin', name: 'Administrator'),
    ],
  ),
  lifecycle: contract.IdentityLifecycleState.active,
);

class MockIdentityRepository implements contract.IdentityRepository {
  contract.IdentityModel? _currentUser;

  @override
  Future<ZenResult<contract.IdentityModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network

    if (password == 'password') {
      _currentUser = _mockIdentity;
      return ZenResult.ok(_currentUser!);
    }

    return const ZenResult.err(
      ZenUnauthorizedError(
          'Invalid email or password (try password="password")'),
    );
  }

  @override
  Future<ZenResult<contract.IdentityModel>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = _mockIdentity;
    return ZenResult.ok(_currentUser!);
  }

  @override
  Future<ZenResult<void>> restorePassword({required String email}) async {
    await Future.delayed(const Duration(seconds: 1));
    return const ZenResult.ok(null);
  }

  @override
  Future<ZenResult<void>> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    return const ZenResult.ok(null);
  }

  @override
  Future<ZenResult<contract.IdentityModel?>> getCurrentIdentity() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ZenResult.ok(_currentUser);
  }
}
