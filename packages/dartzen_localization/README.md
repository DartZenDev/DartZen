# DartZen Localization

[![pub package](https://img.shields.io/pub/v/dartzen_localization.svg)](https://pub.dev/packages/dartzen_localization)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Foundational localization package for the DartZen ecosystem.**

Adheres to strict **Zen Architecture** principles:
- **Explicit over Implicit**: Language is always passed explicitly.
- **Fail Fast**: Missing keys or files throw exceptions in development.
- **Safe Production**: Production mode never crashes; returns keys or safe fallbacks.
- **Zero Global State**: No internal language state.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_localization:
    path: ../dartzen_localization
  flutter:
    sdk: flutter # Required for AssetBundle support
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_localization: ^latest_version
```

## 🚀 Usage

### 1. Configuration

Create a `ZenLocalizationConfig`. Set `isProduction` appropriately (e.g., using `kReleaseMode` or environment variables).

> **Note**: `isProduction` defaults to `true` (Safe Mode) to ensure production safety by default. You must explicitly set it to `false` in development to enable "Fail Fast" behavior.

```dart
import 'package:dartzen_core/dartzen_core.dart'; // Optional: for dzIsPrd
import 'package:dartzen_localization/dartzen_localization.dart';

// Option A: Standard environment check
final config = ZenLocalizationConfig(
  globalPath: 'assets/l10n',
  isProduction: const bool.fromEnvironment('dart.vm.product'),
);

// Option B: Using DartZen Core constants
final configZen = ZenLocalizationConfig(
  globalPath: 'assets/l10n',
  isProduction: dzIsPrd, // Uses DZ_ENV environment variable
);

final service = ZenLocalizationService(config: config);
```

### 2. Loading Messages

Messages must be loaded before use.
- **Global Messages**: Shared across the app.
- **Module Messages**: Specific to a feature module.

```dart
// Load global messages for 'en'
await service.loadGlobalMessages('en');

// Load module messages for 'auth' module
// Must provide explicit path to the module's l10n directory
await service.loadModuleMessages(
  'auth',
  'en',
  modulePath: 'packages/auth/l10n',
);
```

### 3. Translation

Call `translate` with the **explicit language**.

```dart
// Global key
final title = service.translate('app.title', language: 'en');

// Module key (looks in module first, then global)
final login = service.translate('login.btn', language: 'en', module: 'auth');

// Interpolation
final greeting = service.translate(
  'greeting',
  language: 'en',
  params: {'name': 'Zen Developer'},
);
```

## 📁 Localization Files

A strict **Flat JSON** format is enforced.

**Global (`assets/l10n/dartzen.en.json`):**
```json
{
  "app.title": "DartZen App",
  "errors.network": "Network Failure",
  "greeting": "Hello, {name}"
}
```

**Module (`packages/auth/l10n/auth.en.json`):**
```json
{
  "login.btn": "Sign In",
  "errors.auth": "Invalid credentials"
}
```

## ⚖️ Development vs Production

| Feature | Development (isProduction: false) | Production (isProduction: true) |
|---|---|---|
| **Missing Key** | Throws `MissingLocalizationKeyException` | Returns the key (e.g., "app.title") |
| **Missing File** | Throws `MissingLocalizationFileException` | Logs error, allows fallback (no crash) |
| **Missing Param** | Throws `LocalizationInitializationException` | Returns empty string or partial text |
| **Loading** | Loads individual JSON files | Loads **MERGED** single-file assets |

### Error Handling Philosophy

- **Development**: Crash early. Ensure developers define every key and parameter.
- **Production**: Never crash. If a translation is missing, show the key. If interpolation fails, show what's possible.

## 📦 Production Bundling (REQUIRED)

In production, `dartzen_localization` expects a **single merged JSON file** per language to minimize I/O and HTTP requests.

**Runtime merging is NOT performed.** You must run a build step to generate these assets.

### Build Step Description

1. Collect `dartzen.{lang}.json` (Global).
2. Collect all `*.{lang}.json` from modules.
3. Merge them into a single `{lang}.json`.
4. Place in `assets/l10n/`.

### Example Output (`assets/l10n/en.json`):
```json
{
  "app.title": "DartZen App",
  "greeting": "Hello, {name}",
  "login.btn": "Sign In",
  "errors.auth": "Invalid credentials"
}
```

### Flutter Asset Loading

Ensure the merged file is included in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/l10n/en.json
```

## 🏗️ Architecture

- **ZenLocalizationService**: Core logic.
- **ZenLocalizationLoader**: Platform-agnostic loader (IO vs AssetBundle).
- **ZenLocalizationCache**: In-memory caching to prevent redundant loads.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
