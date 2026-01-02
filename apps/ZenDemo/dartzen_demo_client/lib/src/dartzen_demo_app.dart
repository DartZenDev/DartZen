import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';

/// Main application widget.
class ZenDemoApp extends StatefulWidget {
  /// Creates a [ZenDemoApp] widget.
  const ZenDemoApp({required this.apiBaseUrl, super.key});

  /// Base URL for the API.
  final String apiBaseUrl;

  @override
  State<ZenDemoApp> createState() => _ZenDemoAppState();
}

class _ZenDemoAppState extends State<ZenDemoApp> {
  final AppState _appState = AppState();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize localization
    const config = ZenLocalizationConfig(
      isProduction: false,
      globalPath: 'lib/src/l10n',
    );
    final localization = ZenLocalizationService(config: config);

    // Load English
    await localization.loadModuleMessages(
      'dartzen_demo',
      'en',
      modulePath: 'lib/src/l10n',
    );

    // Load Polish
    await localization.loadModuleMessages(
      'dartzen_demo',
      'pl',
      modulePath: 'lib/src/l10n',
    );

    _appState.setLocalization(localization);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) => MaterialApp(
        title: 'Zen Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: _appState.userId == null
            ? WelcomeScreen(appState: _appState, apiBaseUrl: widget.apiBaseUrl)
            : MainScreen(appState: _appState, apiBaseUrl: widget.apiBaseUrl),
      ),
    );
  }
}
