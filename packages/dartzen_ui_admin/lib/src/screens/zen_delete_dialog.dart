import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:flutter/material.dart';

import '../admin/zen_admin_client.dart';
import '../l10n/zen_admin_messages.dart';
import '../theme/admin_theme_extension.dart';

/// Confirmation dialog for deleting an admin resource record.
///
/// Calls [ZenAdminClient.delete] when the user confirms. Uses
/// localized messages from [ZenAdminMessages].
class ZenDeleteDialog extends StatelessWidget {
  /// The transport-backed client for data access.
  final ZenAdminClient client;

  /// The resource name to delete from.
  final String resourceName;

  /// The ID of the record to delete.
  final String id;

  /// Localized messages.
  final ZenAdminMessages messages;

  /// Called after a successful delete.
  final VoidCallback? onSuccess;

  const ZenDeleteDialog({
    super.key,
    required this.client,
    required this.resourceName,
    required this.id,
    required this.messages,
    this.onSuccess,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    try {
      await client.delete(resourceName, id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      onSuccess?.call();
    } on ZenTransportException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AdminThemeExtension>() ??
        AdminThemeExtension.fallback();

    return AlertDialog(
      title: Text(messages.confirmDelete),
      content: Text(messages.deleteConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(messages.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.dangerColor,
            foregroundColor: theme.dangerColor.computeLuminance() > 0.4
                ? const Color(0xFF000000)
                : const Color(0xFFFFFFFF),
          ),
          onPressed: () => _confirmDelete(context),
          child: Text(messages.delete),
        ),
      ],
    );
  }
}
