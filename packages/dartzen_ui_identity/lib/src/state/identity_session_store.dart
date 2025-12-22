import 'dart:async';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity_contract/dartzen_identity_contract.dart'
    as contract;
import 'package:dartzen_identity_domain/dartzen_identity_domain.dart' as domain;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'identity_repository.dart';

/// Providers for accessing the session store and state.
final identitySessionStoreProvider =
    AsyncNotifierProvider<IdentitySessionStore, domain.Identity?>(
  IdentitySessionStore.new,
);

/// Manages the current user session state.
class IdentitySessionStore extends AsyncNotifier<domain.Identity?> {
  late final contract.IdentityRepository _repository;

  @override
  FutureOr<domain.Identity?> build() async {
    _repository = ref.watch(identityRepositoryProvider);
    // Initial load
    final result = await _repository.getCurrentIdentity();
    return result.fold(
      (model) => model != null ? _mapToDomain(model) : null,
      (failure) => null,
    );
  }

  /// Signs in with email and password.
  Future<ZenResult<domain.Identity>> login(
      String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.loginWithEmail(
      email: email,
      password: password,
    );

    return result.fold(
      (model) {
        final identity = _mapToDomain(model);
        state = AsyncValue.data(identity);
        return ZenResult.ok(identity);
      },
      (failure) {
        state = const AsyncValue.data(null);
        return ZenResult.err(failure);
      },
    );
  }

  /// Registers and optionally logs in.
  Future<ZenResult<domain.Identity>> register(
      String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.registerWithEmail(
      email: email,
      password: password,
    );

    return result.fold(
      (model) {
        final identity = _mapToDomain(model);
        state = AsyncValue.data(identity);
        return ZenResult.ok(identity);
      },
      (failure) {
        state = const AsyncValue.data(null);
        return ZenResult.err(failure);
      },
    );
  }

  /// Restores password.
  Future<ZenResult<void>> restorePassword(String email) async {
    return _repository.restorePassword(email: email);
  }

  /// Logs out.
  Future<ZenResult<void>> logout() async {
    state = const AsyncValue.loading();
    final result = await _repository.logout();

    state = const AsyncValue.data(null);
    return result;
  }

  /// Maps [IdentityModel] from contract to domain [Identity].
  domain.Identity _mapToDomain(contract.IdentityModel model) {
    return domain.Identity(
      id: domain.IdentityId.create(model.id.value).dataOrNull!,
      lifecycle: _mapLifecycle(model.lifecycle),
      authority: _mapAuthority(model.authority),
      createdAt: model.createdAt,
    );
  }

  domain.IdentityLifecycle _mapLifecycle(
      contract.IdentityLifecycleState state) {
    switch (state) {
      case contract.IdentityLifecycleState.active:
        return domain.IdentityLifecycle.initial().activate().dataOrNull!;
      case contract.IdentityLifecycleState.suspended:
      case contract.IdentityLifecycleState.locked:
        return domain.IdentityLifecycle.initial()
            .disable('External Lock')
            .dataOrNull!;
      case contract.IdentityLifecycleState.deactivated:
        return domain.IdentityLifecycle.initial()
            .revoke('External Deactivation')
            .dataOrNull!;
      case contract.IdentityLifecycleState.verificationPending:
        return domain.IdentityLifecycle.initial();
    }
  }

  domain.Authority _mapAuthority(contract.Authority model) {
    return domain.Authority(
      roles: model.roles.map((r) => domain.Role(r.name)).toSet(),
      capabilities: model.effectiveCapabilities
          .map((c) => domain.Capability('${c.resource}:${c.action}'))
          .toSet(),
    );
  }
}
