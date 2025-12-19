# DartZen

[![GitHub](https://img.shields.io/badge/GitHub-DartZenDev-blue.svg)](https://github.com/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**The opinionated, scalable core starter kit for Dart & Flutter.**  
Minimalist Shelf backend, secured by Firebase/GCP, managed via Melos.

---

## 🎯 Philosophy

DartZen embraces **minimalism**, **scalability**, and **developer zen**. Built on the principle that less is more, it provides a clean foundation for building production-ready Dart and Flutter applications without unnecessary complexity.

## 📖 Documentation

- [DartZen Contract Model](docs/dartzen_contract_model.md) — The canonical reference for shared meaning between client and server.

## 📦 Repository Structure

This is a **monorepo** managed with [Melos](https://melos.invertase.dev/), containing multiple Dart packages organized for maximum reusability and independent versioning.

```
dartzen/
├── packages/
│   ├── dartzen_core/       # Core runtime and Shelf backend
│   ├── ...
│   └── dartzen_navigation/ # Navigation widget for Flutter applications
├── apps/                   # Example applications (future)
├── melos.yaml              # Monorepo configuration
└── CONTRIBUTING.md         # Contribution guidelines
```

### Packages

- **`dartzen_core`**: Core runtime with Shelf-based HTTP server, Firebase integration, and dependency injection
- **`dartzen_client_transport`**: Minimal HTTP client wrapper for DartZen transport layer
- **`dartzen_localization`**: Foundational localization package for the DartZen ecosystem
- **`dartzen_msgpack`**: Minimal MessagePack implementation for the DartZen ecosystem
- **`dartzen_navigation`**: Unified, adaptive navigation layer for DartZen applications with platform-specific optimizations
- **`dartzen_server_transport`**: Minimal Shelf middleware for DartZen transport layer
- **`dartzen_transport`**: DartZen transport layer for serialization, codec selection, and WebSocket communication

## 🚀 Quick Start

### Prerequisites

- Dart SDK ≥ 3.5.0
- [Melos](https://melos.invertase.dev/) CLI tool

### Setup

1. **Install Melos globally:**
   ```bash
   dart pub global activate melos
   ```

2. **Clone the repository:**
   ```bash
   git clone https://github.com/DartZenDev/DartZen.git
   cd dartzen
   ```

3. **Bootstrap the monorepo:**
   ```bash
   melos bootstrap
   ```
   This installs all dependencies and links local packages.

4. **Run tests:**
   ```bash
   melos run test
   ```

5. **Run analysis:**
   ```bash
   melos run analyze
   ```

6. **Run Android in Debug mode:**
   ```bash
   melos run run:android
   ```

## 🔧 Development Workflow

### Available Melos Scripts

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

#### Run Example

| Command | Description |
|---------|-------------|
| `melos run example:navigation:web` | Run DartZen Navigation package example for Web in Debug mode |
| `melos run example:navigation:ios` | Run DartZen Navigation package example for iOS in Debug mode |

### Making Changes

1. Create a feature branch
2. Make your changes
3. **Use conventional commits** (see [CONTRIBUTING.md](CONTRIBUTING.md))
4. Run tests and analysis
5. Submit a pull request

## 📋 Versioning Strategy

DartZen uses **independent versioning** with [Semantic Versioning (SemVer)](https://semver.org/):

- Each package maintains its own version number
- Versions are automatically calculated from **conventional commit messages**
- Only packages with changes receive version bumps

### How Commits Affect Versions

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix:` | Patch (0.1.0 → 0.1.1) | Bug fixes, minor corrections |
| `feat:` | Minor (0.1.0 → 0.2.0) | New features, enhancements |
| `BREAKING CHANGE:` | Major (0.1.0 → 1.0.0) | Breaking API changes |

**Example:**
```bash
git commit -m "feat(dartzen_core): add authentication middleware"
# dartzen_core: 0.1.0 → 0.2.0

git commit -m "fix(dartzen_navigation): correct type definitions"
# dartzen_navigation: 0.1.0 → 0.1.1
```

Run `melos version --dry-run` to preview version bumps before applying them.

## 🤝 Contributing

We welcome contributions! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) guide for:

- Conventional commit format requirements
- Development workflow
- Code quality standards
- Pull request guidelines

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Melos Documentation](https://melos.invertase.dev/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Dart Shelf](https://pub.dev/packages/shelf)
