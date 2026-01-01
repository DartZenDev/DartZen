import 'package:flutter/material.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../l10n/client_messages.dart';

/// Profile screen displaying user information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.appState,
    required this.apiClient,
    super.key,
  });

  final AppState appState;
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

    try {
      final profile = await widget.apiClient.getProfile(
        userId: widget.appState.userId!,
        language: widget.appState.language,
      );
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = messages.profileError(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final messages = ClientMessages(
          widget.appState.localization!,
          widget.appState.language,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(messages.profileTitle()),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildContent(messages),
          ),
        );
      },
    );
  }

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

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
