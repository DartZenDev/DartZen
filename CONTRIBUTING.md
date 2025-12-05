# Contributing to DartZen

Thank you for your interest in contributing to DartZen! This guide will help you get started.

## 📋 Table of Contents

- [Development Setup](#development-setup)
- [Conventional Commits](#conventional-commits)
- [Development Workflow](#development-workflow)
- [Code Quality Standards](#code-quality-standards)
- [Pull Request Process](#pull-request-process)
- [Versioning Rules](#versioning-rules)

## 🛠️ Development Setup

### Prerequisites

- Dart SDK ≥ 3.5.0
- Git
- [Melos](https://melos.invertase.dev/) CLI tool

### Initial Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/your-username/dartzen.git
   cd dartzen
   ```

2. **Install Melos:**
   ```bash
   dart pub global activate melos
   ```

3. **Bootstrap the monorepo:**
   ```bash
   melos bootstrap
   ```

4. **Verify setup:**
   ```bash
   melos run test
   melos run analyze
   ```

## 📝 Conventional Commits

**MANDATORY:** All commits MUST follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Description | Version Impact |
|------|-------------|----------------|
| `feat` | New feature | Minor (0.1.0 → 0.2.0) |
| `fix` | Bug fix | Patch (0.1.0 → 0.1.1) |
| `docs` | Documentation only | None |
| `style` | Code style changes (formatting, whitespace) | None |
| `refactor` | Code refactoring without feature/fix | None |
| `perf` | Performance improvements | Patch |
| `test` | Adding or updating tests | None |
| `chore` | Maintenance tasks, tooling | None |
| `ci` | CI/CD changes | None |
| `build` | Build system or dependency changes | None |

### Breaking Changes

To indicate a breaking change, add `!` after the type or add `BREAKING CHANGE:` in the footer:

```bash
# Option 1: Exclamation mark
git commit -m "feat(dartzen_core)!: redesign authentication API"

# Option 2: Footer
git commit -m "feat(dartzen_core): redesign authentication API

BREAKING CHANGE: AuthService constructor now requires FirebaseApp instance"
```

**Version impact:** Major (0.1.0 → 1.0.0)

### Scope

The scope indicates which package is affected:

- `dartzen_core` - Core runtime package
- `dartzen_shared` - Shared models package
- `workspace` - Changes affecting the entire monorepo

### Examples

✅ **Good commits:**

```bash
feat(dartzen_core): add JWT authentication middleware
fix(dartzen_shared): correct UserModel serialization
docs(workspace): update README with new examples
refactor(dartzen_core): simplify request handling logic
test(dartzen_shared): add unit tests for validation helpers
```

❌ **Bad commits:**

```bash
# Too vague
fix: bug fix

# Missing scope
feat: add authentication

# Not following format
Added new feature to core package

# Imperative mood violation
Fixed the authentication bug
```

## 🔄 Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Write clean, documented code
- Follow Dart style guidelines
- Add tests for new functionality
- Update documentation as needed

### 3. Commit Changes

```bash
# Stage your changes
git add .

# Commit with conventional format
git commit -m "feat(dartzen_core): add rate limiting middleware"
```

### 4. Run Quality Checks

```bash
# Format code
melos run format

# Run analyzer
melos run analyze

# Run tests
melos run test

# Check formatting without modifying
melos run format:check
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## ✅ Code Quality Standards

### Dart Analysis

All code must pass `dart analyze` with no errors or warnings:

```bash
melos run analyze
```

### Code Formatting

Code must be formatted with `dart format`:

```bash
# Auto-format all code
melos run format

# Check formatting
melos run format:check
```

### Testing

- All new features MUST include tests
- Aim for high test coverage
- Tests must pass before PR approval

```bash
melos run test
```

### Documentation

- Public APIs must have dartdoc comments
- Update README.md if adding user-facing features
- Include examples for complex functionality

## 🔀 Pull Request Process

### Before Creating a PR

- [ ] Code is formatted (`melos run format`)
- [ ] Analysis passes (`melos run analyze`)
- [ ] All tests pass (`melos run test`)
- [ ] Commits follow conventional format
- [ ] Documentation is updated
- [ ] CHANGELOG entries will be auto-generated from commits

### PR Guidelines

1. **Title:** Use conventional commit format
   - Example: `feat(dartzen_core): add authentication middleware`

2. **Description:** Include:
   - What changes were made
   - Why the changes were necessary
   - Any breaking changes
   - Related issue numbers

3. **Review:** Address all reviewer feedback

4. **Merge:** Squash commits if needed to maintain clean history

## 📊 Versioning Rules

DartZen uses **automated versioning** based on conventional commits:

### How It Works

1. Make commits following conventional format
2. Run `melos version --dry-run` to preview version bumps
3. Run `melos version` to apply version bumps and generate changelogs
4. Versions are calculated automatically:
   - `fix:` → Patch bump (0.1.0 → 0.1.1)
   - `feat:` → Minor bump (0.1.0 → 0.2.0)
   - `BREAKING CHANGE:` → Major bump (0.1.0 → 1.0.0)

### Independent Versioning

Each package versions independently:
- `dartzen_core` can be at v2.3.1
- `dartzen_shared` can be at v1.0.5
- Only packages with changes get version bumps

### Example Workflow

```bash
# Make changes and commit
git commit -m "feat(dartzen_core): add middleware support"
git commit -m "fix(dartzen_shared): correct validation logic"

# Preview version changes
melos version --dry-run

# Apply versions (maintainers only)
melos version
git push --follow-tags
```

## 🆘 Getting Help

- **Issues:** Open a GitHub issue for bugs or feature requests
- **Discussions:** Use GitHub Discussions for questions
- **Documentation:** Check the [README.md](README.md) and package docs

## 📜 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the project
- Follow the golden rule: treat others as you'd like to be treated

---

**Thank you for contributing to DartZen!** 🙏
