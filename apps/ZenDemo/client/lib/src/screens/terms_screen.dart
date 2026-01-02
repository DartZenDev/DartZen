import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../l10n/client_messages.dart';

/// Terms and conditions screen.
class TermsScreen extends StatefulWidget {
  /// Creates a [TermsScreen] widget.
  const TermsScreen({
    required this.appState,
    required this.apiClient,
    super.key,
  });

  /// Application state.
  final AppState appState;

  /// API client for server communication.
  final ZenDemoApiClient apiClient;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  TermsContract? _terms;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final messages = ClientMessages(
      widget.appState.localization!,
      widget.appState.language,
    );

    final result = await widget.apiClient.getTerms(
      language: widget.appState.language,
    );

    setState(() {
      result.fold(
        (terms) {
          _terms = terms;
          _isLoading = false;
        },
        (error) {
          // Translate error code to localized message
          _error = messages.translateError(error.message);
          _isLoading = false;
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.appState,
        builder: (context, _) {
          final messages = ClientMessages(
            widget.appState.localization!,
            widget.appState.language,
          );

          return Scaffold(
            appBar: AppBar(
              title: Text(messages.termsTitle()),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(messages),
            ),
          );
        },
      );

  Widget _buildContent(ClientMessages messages) {
    if (_isLoading) {
      return Center(child: Text(messages.termsLoading()));
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Markdown(
      data: _terms!.content,
      selectable: true,
    );
  }
}
