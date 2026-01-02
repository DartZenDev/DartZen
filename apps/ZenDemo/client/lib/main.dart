import 'package:flutter/material.dart';

import 'src/zen_demo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8888',
  );

  runApp(const ZenDemoApp(apiBaseUrl: apiBaseUrl));
}
