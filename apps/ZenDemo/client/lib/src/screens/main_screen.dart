import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../l10n/client_messages.dart';
import '../websocket_client.dart';
import 'profile_screen.dart';
import 'terms_screen.dart';

/// Main screen with all demo features.
class MainScreen extends StatefulWidget {
  /// Creates a [MainScreen] widget.
  const MainScreen({
    required this.appState,
    required this.apiBaseUrl,
    super.key,
  });

  /// Application state.
  final AppState appState;

  /// Base URL for the API.
  final String apiBaseUrl;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final ZenDemoApiClient _apiClient;
  late final ZenDemoWebSocketClient _wsClient;
  String? _pingResult;
  String _wsStatus = 'disconnected';
  String? _wsMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = ZenDemoApiClient(baseUrl: widget.apiBaseUrl);
    _wsClient = ZenDemoWebSocketClient(
      wsUrl: '${widget.apiBaseUrl.replaceFirst('http', 'ws')}/ws',
    );
  }

  @override
  void dispose() {
    _wsClient.disconnect();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
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
              title: Text(messages.welcomeTitle()),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) => widget.appState.setLanguage(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'en', child: Text('English')),
                    const PopupMenuItem(value: 'pl', child: Text('Polski')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(messages.mainLanguage()),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildPingSection(messages),
                  const Divider(height: 32),
                  _buildWebSocketSection(messages),
                  const Divider(height: 32),
                  _buildNavigationSection(messages),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildPingSection(ClientMessages messages) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _handlePing,
            child: Text(messages.mainPing()),
          ),
          if (_pingResult != null) ...[
            const SizedBox(height: 8),
            Text(_pingResult!),
          ],
        ],
      );

  Widget _buildWebSocketSection(ClientMessages messages) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: _wsClient.isConnected
                    ? _handleWsDisconnect
                    : _handleWsConnect,
                child: Text(
                  _wsClient.isConnected
                      ? messages.mainWebSocketDisconnect()
                      : messages.mainWebSocketConnect(),
                ),
              ),
              const SizedBox(width: 8),
              if (_wsClient.isConnected)
                ElevatedButton(
                  onPressed: _handleWsSend,
                  child: Text(messages.mainWebSocketSend()),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(messages.mainWebSocketStatus(_wsStatus)),
          if (_wsMessage != null) ...[
            const SizedBox(height: 8),
            Text(messages.mainWebSocketReceived(_wsMessage!)),
          ],
        ],
      );

  Widget _buildNavigationSection(ClientMessages messages) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _navigateToProfile,
            child: Text(messages.mainViewProfile()),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _navigateToTerms,
            child: Text(messages.mainViewTerms()),
          ),
        ],
      );

  Future<void> _handlePing() async {
    final messages = ClientMessages(
      widget.appState.localization!,
      widget.appState.language,
    );

    try {
      final result = await _apiClient.ping(language: widget.appState.language);
      setState(() {
        _pingResult = messages.mainPingSuccess(result.message);
      });
    } catch (e) {
      setState(() {
        _pingResult = messages.mainPingError(e.toString());
      });
    }
  }

  void _handleWsConnect() {
    _wsClient.connect();
    _wsClient.messages?.listen((message) {
      setState(() {
        _wsMessage = message.payload;
      });
    });
    setState(() {
      _wsStatus = 'connected';
    });
  }

  void _handleWsDisconnect() {
    _wsClient.disconnect();
    setState(() {
      _wsStatus = 'disconnected';
      _wsMessage = null;
    });
  }

  void _handleWsSend() {
    final message = WebSocketMessageContract(
      type: 'message',
      payload: 'Hello from ZenDemo at ${DateTime.now()}',
    );
    _wsClient.send(message);
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ProfileScreen(appState: widget.appState, apiClient: _apiClient),
      ),
    );
  }

  void _navigateToTerms() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            TermsScreen(appState: widget.appState, apiClient: _apiClient),
      ),
    );
  }
}
