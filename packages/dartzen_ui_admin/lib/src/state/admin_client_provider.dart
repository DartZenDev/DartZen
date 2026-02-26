import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/zen_admin_client.dart';

/// Provider for [ZenAdminClient].
///
/// MUST be overridden in the main application's [ProviderScope].
final zenAdminClientProvider = Provider<ZenAdminClient>((ref) {
  throw UnimplementedError('zenAdminClientProvider must be overridden');
});
