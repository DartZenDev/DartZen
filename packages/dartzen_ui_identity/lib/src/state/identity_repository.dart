import 'package:dartzen_identity_contract/dartzen_identity_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [IdentityRepository].
///
/// MUST be overridden in the main application's [ProviderScope].
final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  throw UnimplementedError('identityRepositoryProvider must be overridden');
});
