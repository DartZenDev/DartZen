import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';

/// One-time setup to create a fake valid identity
final _mockIdentity = IdentityContract(
  id: 'user-123',
  createdAt: ZenTimestamp.now().millisecondsSinceEpoch,
  authority: const AuthorityContract(
    roles: ['USER', 'ADMIN'],
    capabilities: ['can_edit_profile'],
  ),
  lifecycle: const IdentityLifecycleContract(state: 'active'),
);

class MockIdentityRepository implements IdentityRepository {
  IdentityContract? _currentUser;

  @override
  Future<ZenResult<IdentityContract>> loginWithEmail({
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
        'Invalid email or password (try password="password")',
      ),
    );
  }

  @override
  Future<ZenResult<IdentityContract>> registerWithEmail({
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
  Future<ZenResult<IdentityContract?>> getCurrentIdentity() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ZenResult.ok(_currentUser);
  }
}
