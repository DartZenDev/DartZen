# Development Workflow

## 📋 Prerequisites

- Dart SDK ≥ 3.5.0
- [Melos](https://melos.invertase.dev/) CLI tool

## 🛠️ Setup

1. **Install Melos globally:**
   ```bash
   dart pub global activate melos
   ```

2. **Bootstrap the monorepo:**
   ```bash
   melos bootstrap
   ```
   This installs all dependencies and links local packages.

3. **Run tests:**
   ```bash
   melos run test
   ```

4. **Run analysis:**
   ```bash
   melos run analyze
   ```

## 🤖 Melos Scripts

| Command | Description |
|---------|-------------|
| `melos bootstrap` | Install dependencies and link packages |
| `melos clean` | Clean all packages |
| `melos run analyze` | Run Dart analyzer on all packages |
| `melos run format` | Format all Dart code |
| `melos run format:check` | Check formatting without modifying files |
| `melos run test` | Run tests in all packages |
| `melos version` | Version packages based on conventional commits |
| `melos run publish` | Publish packages to pub.dev (dry-run mode) |
| `melos run run:android` | Run Android in Debug mode |
| `melos run run:android:profile` | Run Android in Profile mode |
| `melos run run:android:release` | Run Android in Release mode |
| `melos run run:ios` | Run iOS in Debug mode |
| `melos run run:ios:profile` | Run iOS in Profile mode |
| `melos run run:ios:release` | Run iOS in Release mode |
| `melos run run:web` | Run Web in Debug mode |
| `melos run run:web:profile` | Run Web in Profile mode |
| `melos run run:web:release` | Run Web in Release mode |
| `melos run run:desktop:windows` | Run Windows in Debug mode |
| `melos run run:desktop:windows:profile` | Run Windows in Profile mode |
| `melos run run:desktop:windows:release` | Run Windows in Release mode |
| `melos run run:desktop:macos` | Run macOS in Debug mode |
| `melos run run:desktop:macos:profile` | Run macOS in Profile mode |
| `melos run run:desktop:macos:release` | Run macOS in Release mode |
| `melos run run:desktop:linux` | Run Linux in Debug mode |
| `melos run run:desktop:linux:profile` | Run Linux in Profile mode |
| `melos run run:desktop:linux:release` | Run Linux in Release mode |

### Running Examples

| Command | Description |
|---------|-------------|
| `melos run example:navigation:web` | Run DartZen Navigation package example for Web in Debug mode |
| `melos run example:navigation:ios` | Run DartZen Navigation package example for iOS in Debug mode |
| `melos run example:identity:web` | Run DartZen Identity package example for Web in Debug mode |
| `melos run example:identity:ios` | Run DartZen Identity package example for iOS in Debug mode |

## 🛠️ Making Changes

1. Create a feature branch
2. Make your changes
3. **Use conventional commits** (see [CONTRIBUTING.md](../CONTRIBUTING.md))
4. Run tests and analysis
5. Submit a pull request

## 🔗 Links

- [Melos Documentation](https://melos.invertase.dev/)
- [Dart Shelf](https://pub.dev/packages/shelf)
