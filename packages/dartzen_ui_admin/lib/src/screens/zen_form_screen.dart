import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:flutter/material.dart';

import '../admin/zen_admin_client.dart';
import '../admin/zen_admin_field.dart';
import '../admin/zen_admin_resource.dart';
import '../l10n/zen_admin_messages.dart';
import '../theme/admin_theme_extension.dart';

/// Screen for creating or editing an admin resource record.
///
/// When [id] is `null`, the screen operates in **create** mode.
/// When [id] is provided, the screen operates in **edit** mode and
/// fetches the existing record on initialization.
class ZenFormScreen extends StatefulWidget {
  /// The resource metadata describing fields and permissions.
  final ZenAdminResource<dynamic> resource;

  /// The transport-backed client for data access.
  final ZenAdminClient client;

  /// Localized messages.
  final ZenAdminMessages messages;

  /// The record ID to edit. `null` for create mode.
  final String? id;

  /// Called after a successful create or update.
  final VoidCallback? onSuccess;

  const ZenFormScreen({
    super.key,
    required this.resource,
    required this.client,
    required this.messages,
    this.id,
    this.onSuccess,
  });

  @override
  State<ZenFormScreen> createState() => _ZenFormScreenState();
}

class _ZenFormScreenState extends State<ZenFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;
  bool _initialLoading = false;
  String? _error;

  bool get _isEditMode => widget.id != null;

  List<ZenAdminField> get _editableFields =>
      widget.resource.fields.where((f) => f.editable).toList();

  @override
  void initState() {
    super.initState();
    for (final field in _editableFields) {
      _controllers[field.name] = TextEditingController();
    }
    if (_isEditMode) {
      _fetchRecord();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchRecord() async {
    setState(() => _initialLoading = true);

    try {
      final data = await widget.client.fetchById(
        widget.resource.resourceName,
        widget.id!,
      );
      if (!mounted) return;
      for (final field in _editableFields) {
        final value = data[field.name];
        if (value != null) {
          _controllers[field.name]?.text = '$value';
        }
      }
      setState(() => _initialLoading = false);
    } on ZenTransportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _initialLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final data = <String, dynamic>{};
    for (final field in _editableFields) {
      data[field.name] = _controllers[field.name]?.text ?? '';
    }

    try {
      if (_isEditMode) {
        await widget.client.update(
          widget.resource.resourceName,
          widget.id!,
          data,
        );
      } else {
        await widget.client.create(widget.resource.resourceName, data);
      }
      if (!mounted) return;
      widget.onSuccess?.call();
    } on ZenTransportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AdminThemeExtension>() ??
        AdminThemeExtension.fallback();
    final title = _isEditMode
        ? widget.messages.editTitle
        : widget.messages.createTitle;

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        title: Text(
          '$title — ${widget.resource.displayName}',
          style: theme.titleStyle,
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(AdminThemeExtension theme) {
    if (_initialLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: theme.spacing),
            Text(widget.messages.loading),
          ],
        ),
      );
    }

    if (_error != null &&
        _isEditMode &&
        _controllers.values.every((c) => c.text.isEmpty)) {
      return Center(
        child: Text(_error!, style: TextStyle(color: theme.onSurfaceColor)),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: theme.containerPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._editableFields.map((field) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: theme.spacing),
                    child: TextFormField(
                      controller: _controllers[field.name],
                      decoration: InputDecoration(
                        labelText: field.label,
                        border: const OutlineInputBorder(),
                      ),
                      validator: field.required
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return widget.messages.requiredField;
                              }
                              return null;
                            }
                          : null,
                    ),
                  );
                }),
                SizedBox(height: theme.spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: Text(widget.messages.cancel),
                    ),
                    SizedBox(width: theme.spacing),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.messages.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
