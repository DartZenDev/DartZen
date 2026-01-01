import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/zen_demo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase options for web emulator
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:123456789:web:abcdef',
        messagingSenderId: '123456789',
        projectId: 'demo-zen',
        authDomain: 'localhost',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  const authEmulatorHost = String.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_HOST',
    defaultValue: 'localhost:9099',
  );

  if (authEmulatorHost.isNotEmpty) {
    final parts = authEmulatorHost.split(':');
    if (parts.length == 2) {
      final host = parts[0];
      final port = int.tryParse(parts[1]);
      if (port != null) {
        await FirebaseAuth.instance.useAuthEmulator(host, port);
      }
    }
  }

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8888',
  );

  runApp(const ZenDemoApp(apiBaseUrl: apiBaseUrl));
}
