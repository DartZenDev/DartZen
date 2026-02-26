import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:flutter/material.dart';

import '../admin/zen_admin_client.dart';
import '../admin/zen_admin_field.dart';
import '../admin/zen_admin_page.dart';
import '../admin/zen_admin_permissions.dart';
import '../admin/zen_admin_query.dart';
import '../admin/zen_admin_resource.dart';
import '../l10n/zen_admin_messages.dart';
import '../theme/admin_theme_extension.dart';

/// Screen that displays a paginated list of admin resource records.
///
/// Uses [ZenAdminClient] to fetch data and [ZenAdminResource] metadata
/// to determine which fields to show and which actions are available.
class ZenListScreen extends StatefulWidget {
  /// The resource metadata describing fields and permissions.
  final ZenAdminResource<dynamic> resource;

  /// The transport-backed client for data access.
  final ZenAdminClient client;

  /// Localized messages.
  final ZenAdminMessages messages;

  /// Called when the user taps the edit action for a record.
  final ValueChanged<String>? onEdit;

  /// Called when the user taps the delete action for a record.
  final ValueChanged<String>? onDelete;

  /// Called when the user taps the create button.
  final VoidCallback? onCreate;

  const ZenListScreen({
    super.key,
    required this.resource,
    required this.client,
    required this.messages,
    this.onEdit,
    this.onDelete,
    this.onCreate,
  });

  @override
  State<ZenListScreen> createState() => _ZenListScreenState();
}

class _ZenListScreenState extends State<ZenListScreen> {
  ZenAdminPage<Map<String, dynamic>>? _page;
  bool _loading = true;
  String? _error;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await widget.client.query(
        widget.resource.resourceName,
        ZenAdminQuery(offset: _offset, limit: _limit),
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } on ZenTransportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _nextPage() {
    final page = _page;
    if (page == null) return;
    if (_offset + _limit < page.total) {
      _offset += _limit;
      _fetchPage();
    }
  }

  void _previousPage() {
    if (_offset > 0) {
      _offset = (_offset - _limit).clamp(0, _offset);
      _fetchPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AdminThemeExtension>() ??
        AdminThemeExtension.fallback();
    final permissions = widget.resource.permissions;
    final visibleFields = widget.resource.fields
        .where((f) => f.visibleInList)
        .toList();

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        title: Text(
          '${widget.resource.displayName} — ${widget.messages.listTitle}',
          style: theme.titleStyle,
        ),
      ),
      floatingActionButton: permissions.canWrite
          ? FloatingActionButton(
              onPressed: widget.onCreate,
              child: Semantics(
                label: widget.messages.createTitle,
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: _buildBody(theme, permissions, visibleFields),
    );
  }

  Widget _buildBody(
    AdminThemeExtension theme,
    ZenAdminPermissions permissions,
    List<ZenAdminField> visibleFields,
  ) {
    if (_loading) {
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

    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: theme.onSurfaceColor)),
      );
    }

    final page = _page;
    if (page == null || page.items.isEmpty) {
      return Center(
        child: Text(
          widget.messages.noItems,
          style: TextStyle(color: theme.onSurfaceColor),
        ),
      );
    }

    final showActions = permissions.canWrite || permissions.canDelete;

    return Padding(
      padding: theme.containerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(theme.headerColor),
                  columns: [
                    ...visibleFields.map(
                      (f) => DataColumn(label: Text(f.label)),
                    ),
                    if (showActions)
                      DataColumn(label: Text(widget.messages.actions)),
                  ],
                  rows: List<DataRow>.generate(page.items.length, (index) {
                    final item = page.items[index];
                    final rowColor = index.isEven
                        ? theme.rowColor
                        : theme.alternateRowColor;

                    return DataRow(
                      color: WidgetStateProperty.all(rowColor),
                      cells: [
                        ...visibleFields.map(
                          (f) => DataCell(
                            Text(
                              '${item[f.name] ?? ''}',
                              style: theme.bodyStyle,
                            ),
                          ),
                        ),
                        if (showActions)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (permissions.canWrite)
                                  Semantics(
                                    label: widget.messages.edit,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: theme.actionColor,
                                      ),
                                      onPressed: () {
                                        final id =
                                            item[widget.resource.idFieldName]
                                                ?.toString();
                                        if (id != null) {
                                          widget.onEdit?.call(id);
                                        }
                                      },
                                    ),
                                  ),
                                if (permissions.canDelete)
                                  Semantics(
                                    label: widget.messages.delete,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: theme.dangerColor,
                                      ),
                                      onPressed: () {
                                        final id =
                                            item[widget.resource.idFieldName]
                                                ?.toString();
                                        if (id != null) {
                                          widget.onDelete?.call(id);
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          _buildPagination(theme, page),
        ],
      ),
    );
  }

  Widget _buildPagination(
    AdminThemeExtension theme,
    ZenAdminPage<Map<String, dynamic>> page,
  ) {
    final hasPrev = _offset > 0;
    final hasNext = _offset + _limit < page.total;

    return Padding(
      padding: EdgeInsets.only(top: theme.spacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: widget.messages.previousPage,
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: widget.messages.previousPage,
              onPressed: hasPrev ? _previousPage : null,
            ),
          ),
          Text(
            '${_offset + 1}–${(_offset + page.items.length).clamp(0, page.total)} '
            'of ${page.total}',
            style: TextStyle(color: theme.onSurfaceColor),
          ),
          Semantics(
            label: widget.messages.nextPage,
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: widget.messages.nextPage,
              onPressed: hasNext ? _nextPage : null,
            ),
          ),
        ],
      ),
    );
  }
}
