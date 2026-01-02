import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';

/// Identity lifecycle errors for demo flows.
enum IdentityError {
  /// Identity creation or activation failed.
  createFailed,
}

/// Code accessor for [IdentityError].
extension IdentityErrorCode on IdentityError {
  /// Returns the string representation expected by clients.
  String get code => name;
}

/// Service that encapsulates identity lifecycle operations for the demo.
class IdentityService {
  /// Creates an [IdentityService] backed by Firestore.
  IdentityService({required FirestoreIdentityRepository repository})
    : _repository = repository;

  final FirestoreIdentityRepository _repository;

  /// Retrieves an identity or creates and activates a demo one.
  Future<ZenResult<Identity>> getOrCreateDemoIdentity(IdentityId id) async {
    final existing = await _repository.getIdentityById(id);
    if (existing.isSuccess && existing.dataOrNull != null) {
      return ZenResult.ok(existing.dataOrNull!);
    }

    final pending = Identity.createPending(
      id: id,
      authority: Authority(roles: {Role.user}),
    );

    final activateResult = pending.lifecycle.activate();
    if (!activateResult.isSuccess) {
      return ZenResult.err(ZenUnknownError(IdentityError.createFailed.code));
    }

    final activeIdentity = Identity(
      id: pending.id,
      lifecycle: activateResult.dataOrNull!,
      authority: pending.authority,
      createdAt: pending.createdAt,
    );

    final storeResult = await _repository.createIdentity(activeIdentity);
    if (!storeResult.isSuccess) {
      return ZenResult.err(ZenUnknownError(IdentityError.createFailed.code));
    }

    return ZenResult.ok(activeIdentity);
  }
}
