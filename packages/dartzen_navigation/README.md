# DartZen Navigation

[![pub package](https://img.shields.io/pub/v/dartzen_navigation.svg)](https://pub.dev/packages/dartzen_navigation)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Unified, adaptive navigation layer for DartZen applications with platform-specific optimizations.**

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 📊 Features

✨ **Platform Adaptive** - Automatically adapts to mobile, web, and desktop platforms
📱 **Responsive** - Smart overflow handling and breakpoint-based layouts
🚀 **Zero Configuration** - Sensible defaults with customization options

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dartzen_navigation: ^0.1.0
```

## 🚀 Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:dartzen_navigation/dartzen_navigation.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Define your navigation items
  final List<ZenNavigationItem> _navItems = const [
    ZenNavigationItem(
      id: 'home',
      label: 'Home',
      icon: Icons.home,
      builder: (context) => HomeScreen(),
    ),
    ZenNavigationItem(
      id: 'search',
      label: 'Search',
      icon: Icons.search,
      builder: (context) => SearchScreen(),
    ),
    ZenNavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person,
      builder: (context) => ProfileScreen(),
      badgeCount: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ZenNavigation(
      items: _navItems,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
    );
  }
}
```

## 📱 Platform Support

The package supports the following platforms:

- Android
- iOS
- Web
- Desktop

The tree-shaking feature is implemented via the environment variable `DZ_PLATFORM`. This is a compile-time constant that is used to conditionally include or exclude platform-specific code. Additionally, the `DZ_PLATFORM` is used to conditionally include or exclude platform-specific assets to provide the best possible experience for each platform.

To run the example, use the following commands:

```bash
flutter run --dart-define=DZ_PLATFORM=ios # and select iPhone

flutter run -d chrome --dart-define=DZ_PLATFORM=web
flutter run -d macos --dart-define=DZ_PLATFORM=macos
flutter run -d windows --dart-define=DZ_PLATFORM=windows
flutter run -d linux --dart-define=DZ_PLATFORM=linux
flutter run -d android --dart-define=DZ_PLATFORM=android
flutter run -d ios --dart-define=DZ_PLATFORM=ios
```

## 📛 Badge Support

Show notification badges on navigation items:

```dart
const ZenNavigationItem(
  id: 'messages',
  label: 'Messages',
  icon: Icons.message,
  builder: (context) => MessagesScreen(),
  badgeCount: 5, // Shows a badge with "5"
);
```

## 🏭 Overflow Management

The package automatically handles overflow items on Mobile when there are more than 4 items to display. Extra items are moved to a "More" menu. The 'more' is customizable.

```dart
ZenNavigation(
  items: _navItems,
  selectedIndex: 0,
  onItemSelected: (i) { /* Handle navigation */ },
  labelMore: 'More',
)
```

## 📊 Example

The example can be found in the [`example/`](example) directory.

## Design Principles

Following DartZen's Zen principles:

- **Simplicity** - No priority fields, order determined by list position
- **External Source of Truth** - Bring you own state management
- **Maximum Predictability** - No code generation, you see all the code

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
