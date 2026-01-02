import 'package:dartzen_demo_contracts/dartzen_demo_contracts.dart';
import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../l10n/client_messages.dart';

/// Profile screen displaying user information.
class ProfileScreen extends StatefulWidget {
  /// Creates a [ProfileScreen] widget.
  const ProfileScreen({
    required this.appState,
    required this.apiClient,
    super.key,
  });

  /// Application state.
  final AppState appState;

  /// API client for server communication.
  final ZenDemoApiClient apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileContract? _profile;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final messages = ClientMessages(
      widget.appState.localization!,
      widget.appState.language,
    );

    final result = await widget.apiClient.getProfile(
      userId: widget.appState.userId!,
      language: widget.appState.language,
    );

    setState(() {
      result.fold(
        (profile) {
          _profile = profile;
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
        appBar: AppBar(title: Text(messages.profileTitle())),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(messages),
        ),
      );
    },
  );

  Widget _buildContent(ClientMessages messages) {
    if (_isLoading) {
      return Center(child: Text(messages.profileLoading()));
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(messages.profileUserId(), _profile!.userId),
        const SizedBox(height: 16),
        _buildField(messages.profileDisplayName(), _profile!.displayName),
        const SizedBox(height: 16),
        _buildField(messages.profileEmail(), _profile!.email),
        const SizedBox(height: 16),
        if (_profile!.bio != null) ...[
          _buildField(messages.profileBio(), _profile!.bio!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(value),
    ],
  );
}
