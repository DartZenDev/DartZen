# DartZen

**The opinionated, scalable core starter kit for Dart & Flutter.**  
Minimalist Shelf backend, secured by Firebase/GCP, managed via Melos.

---

## 🎯 Philosophy

DartZen embraces **minimalism**, **scalability**, and **developer zen**. Built on the principle that less is more, it provides a clean foundation for building production-ready Dart and Flutter applications without unnecessary complexity.

## 📦 Repository Structure

This is a **monorepo** managed with [Melos](https://melos.invertase.dev/), containing multiple Dart packages organized for maximum reusability and independent versioning.

```
dartzen/
├── packages/
│   ├── dartzen_shared/    # Shared models and contracts
│   └── dartzen_core/      # Core runtime and Shelf backend
├── apps/                  # Example applications (future)
├── melos.yaml            # Monorepo configuration
└── CONTRIBUTING.md       # Contribution guidelines
```

### Packages

- **`dartzen_shared`**: Shared models, contracts, and type definitions used across all DartZen packages
- **`dartzen_core`**: Core runtime with Shelf-based HTTP server, Firebase integration, and dependency injection

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
   git clone https://github.com/your-org/dartzen.git
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

git commit -m "fix(dartzen_shared): correct type definitions"
# dartzen_shared: 0.1.0 → 0.1.1
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
