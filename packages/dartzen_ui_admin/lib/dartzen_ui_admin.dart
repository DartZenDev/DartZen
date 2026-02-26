/// Reusable Admin UI framework for DartZen applications.
///
/// Provides transport-backed CRUD screens, resource metadata models,
/// and a permission-aware UI layer. All data access goes through
/// [ZenAdminClient] which delegates to the DartZen transport layer.
library;

// Admin models
export 'src/admin/zen_admin_client.dart';
export 'src/admin/zen_admin_field.dart';
export 'src/admin/zen_admin_page.dart';
export 'src/admin/zen_admin_permissions.dart';
export 'src/admin/zen_admin_query.dart';
export 'src/admin/zen_admin_resource.dart';
// L10n
export 'src/l10n/zen_admin_messages.dart';
// Screens
export 'src/screens/zen_delete_dialog.dart';
export 'src/screens/zen_form_screen.dart';
export 'src/screens/zen_list_screen.dart';
// State
export 'src/state/admin_client_provider.dart';
// Theme
export 'src/theme/admin_theme_extension.dart';
