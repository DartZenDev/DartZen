import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_state.dart';
import '../l10n/client_messages.dart';

/// Welcome screen for ZenDemo.
class WelcomeScreen extends StatefulWidget {
  /// Creates a [WelcomeScreen] widget.
  const WelcomeScreen({
    required this.appState,
    required this.apiBaseUrl,
    super.key,
  });

  /// Application state.
  final AppState appState;

  /// Base URL for the API.
  final String apiBaseUrl;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final ZenDemoApiClient _apiClient;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = ZenDemoApiClient(baseUrl: widget.apiBaseUrl);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ClientMessages(
      widget.appState.localization!,
      widget.appState.language,
    );

    return Scaffold(
      appBar: AppBar(title: Text(messages.welcomeTitle())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  messages.welcomeSubtitle(),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Test credentials:\ndemo@example.com / admin@example.com\npassword: password123',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiClient.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      result.fold(
        (loginResponse) {
          // Success - store user ID and token in app state
          widget.appState.setIdToken(loginResponse.idToken);
          widget.appState.setUserId(loginResponse.userId);
        },
        (error) {
          // Error - translate error code to localized message
          final messages = ClientMessages(
            widget.appState.localization!,
            widget.appState.language,
          );
          setState(() {
            _errorMessage = messages.translateError(error.message);
          });
        },
      );
    }
  }
}
