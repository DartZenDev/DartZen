# DartZen UI Identity

[![pub package](https://img.shields.io/pub/v/dartzen_ui_identity.svg)](https://pub.dev/packages/dartzen_ui_identity)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

A cross-platform, adaptive UI package for DartZen Identity flows, built with domain purity and performance in mind.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## ⚙️ Features

- **Adaptive Design**: Widgets and screens automatically adapt to Mobile and Desktop layouts.
- **Domain Pure**: Strictly respects `dartzen_identity_domain` contracts.
- **Strongly Typed Localization**: Seamless integration with `dartzen_localization`.
- **Navigation Ready**: Built-in support for `dartzen_navigation` shell patterns.

## 📦 Components

- `IdentityTextField`: Reusable brand-themed input.
- `IdentityButton`: Adaptive button with built-in loading states.
- `IdentityStatusChip`: Semi-transparent status indicators.
- `LoginScreen`, `RegisterScreen`, `RestorePasswordScreen`, `ProfileScreen`, `AuthorityRolesScreen`.

## 📚 Getting Started

### 1. Theming

Add `IdentityThemeExtension` to your `ThemeData`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      IdentityThemeExtension.fallback(), // Or customize with your colors
    ],
  ),
  ...
);
```

### 2. Localization

Load `IdentityMessages` in your app initialization:

```dart
final messages = IdentityMessages(localizationService, 'en');
await messages.load();
```

## 🏗️ Running the Example

The example app demonstrates all identity flows integrated with `dartzen_navigation`.

### Prerequisites

Ensure you are at the monorepo root:

```bash
cd ~/DartZen
melos bootstrap
```

### Start Example

Navigate to the monorepo root and run:

```bash
melos run example:identity:web
```

### Navigation Integration


The example app showcases how to use `ZenNavigation` with `IdentityMessages`. It uses a custom `HomeScreen` wrapper to bridge `go_router` states with `ZenNavigation` items, providing a unified sidebar/bottom bar experience across identity screens.

Refer to [example/lib/main.dart](example/lib/main.dart) for implementation details.

## 📊 Telemetry Integration

`dartzen_ui_identity` screens provide identity-aware callbacks that allow you to easily integrate telemetry and analytics (like Google Analytics or Firebase Analytics) without the package depending on any specific library.

### Example: Tracking Login Success

```dart
LoginScreen(
  messages: messages,
  onLoginSuccessWithIdentity: (Identity identity) {
    // 1. Log event to your analytics provider
    analytics.logEvent(
      name: 'login',
      parameters: {
        'user_id': identity.id.value,
        'method': 'email_password',
      },
    );

    // 2. Perform navigation
    context.go('/home');
  },
)
```

By using these callbacks, you can capture full domain metadata at the moment of success.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
