# Versioning and Releases

## 🏁 Versioning Strategy

DartZen uses **independent versioning** with [Semantic Versioning (SemVer)](https://semver.org/):

- Each package maintains its own version number
- Versions are automatically calculated from **conventional commit messages**
- Only packages with changes receive version bumps

## 📝 Conventional Commits Mapping

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix:` | Patch (0.1.0 → 0.1.1) | Bug fixes, minor corrections |
| `feat:` | Minor (0.1.0 → 0.2.0) | New features, enhancements |
| `BREAKING CHANGE:` | Major (0.1.0 → 1.0.0) | Breaking API changes |

### Examples

```bash
git commit -m "feat(dartzen_core): add authentication middleware"
# dartzen_core: 0.1.0 → 0.2.0

git commit -m "fix(dartzen_ui_navigation): correct type definitions"
# dartzen_ui_navigation: 0.1.0 → 0.1.1
```

## 🔄 Melos Workflow

Run `melos version --dry-run` to preview version bumps before applying them.

## 🔗 Links

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
