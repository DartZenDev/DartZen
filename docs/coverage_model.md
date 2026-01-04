# Coverage model and aggregation

## 🪷 Coverage philosophy

DartZen targets **maximal achievable test coverage** while preserving
**compile-time tree shaking** and **deterministic builds**.

Coverage numbers in this repository are:
- aggregated across multiple build environments (DEV and PRD)
- aggregated across multiple platforms
- never interpreted from a single test run

A single coverage report is not considered authoritative.
Only the aggregated result reflects real coverage.

## 🛠️ Coverage aggregation

This repository includes a helper script to compute per-package and aggregate
coverage: `./scripts/compute_local_coverage.sh`.

- Run it from the repository root. It expects coverage artifacts under `packages/*/coverage` and `apps/*/*/coverage` (the script scans both trees).
- The script prefers an existing `coverage/lcov.info` for a package when that file is newer than any `coverage/test/*.vm.json` artifacts. This prevents an older JSON-to-LCOV conversion from overwriting a fresh `flutter test --coverage` result.

To regenerate and include `dartzen_localization` coverage (example):

```bash
# from repo root
cd /path/to/DartZen
cd packages/dartzen_localization && flutter test --coverage
# then from repo root
./scripts/compute_local_coverage.sh
```

If you want to force re-conversion from VM JSON files, either remove the
package `coverage/lcov.info` (or `lcov_dev.info` / `lcov_prd.info`) or delete
the `coverage/test` VM JSON files (or the per-run `coverage_<env>_*/test/*.vm.json`)
before running the script.

Coverage artifacts from different environments (DEV/PRD) are **complementary**.
Missing coverage in one environment may be provided by another.

## ⚙️ Canonical upload files and expected `melos` behavior

- CI uploads per-package, per-environment LCOV files: `packages/<pkg>/coverage/lcov_prd.info` and `packages/<pkg>/coverage/lcov_dev.info`. For apps the equivalent paths are `apps/<app>/coverage/lcov_prd.info` and `apps/<app>/coverage/lcov_dev.info`.
- The repository's `melos run test:matrix` task should run the test matrix (PRD and DEV combinations and platforms) and produce coverage artifacts either as VM JSON under `packages/<pkg>/coverage/test/*.vm.json` (or `apps/<app>/coverage/...`) or (for Flutter tests) directly as `packages/<pkg>/coverage/lcov.info` / `apps/<app>/coverage/lcov.info`.
- The repository's `melos run test:matrix` task runs the matrix and produces coverage artifacts. The `test:matrix` script creates per-run coverage directories named like `coverage_<env>_<platform>_dart` or `coverage_<env>_<platform>_flutter` inside each package; those dirs contain a `test/*.vm.json` output. The CI conversion steps convert those directories into `lcov_prd.info` and `lcov_dev.info` per package for upload.
- The CI workflow converts VM JSON -> LCOV per-package into `lcov_prd.info` and `lcov_dev.info` and then uploads those files to Codecov. The compute script `./scripts/compute_local_coverage.sh` is a local/CI sanity tool that normalizes/merges these LCOVs and computes an aggregate percentage.

If your `melos run test:matrix` does not produce per-package or per-app coverage artifacts, the CI assertion step will fail; ensure `melos run test:matrix` is run from the repo root, that the root `pubspec.yaml` `workspace:` includes the packages/apps you expect, and that any package requiring workspace resolution includes `resolution: workspace` in its own `pubspec.yaml`. Also ensure each package/app test task writes coverage to its `coverage` directory.

## 🧭 Environment-based coverage model

DartZen codebases use compile-time environment constants (`DZ_ENV`,
`DZ_PLATFORM`, `DZ_IS_TEST`) to enable:

- dead-code elimination via tree shaking
- strict separation of DEV and PRD code paths
- deterministic coverage per build configuration

Important rules:

- `DZ_ENV` controls **which code paths exist** in a given build.
- DEV and PRD branches are tested in **separate runs** and merged.
- `DZ_IS_TEST` is allowed **only for dependency wiring and initialization**.
- `DZ_IS_TEST` must never introduce a third behavioral branch or alter
  business logic outcomes.

Full coverage is defined as:
> all reachable code paths across DEV and PRD builds are executed by tests.

## 📋 Inventory uncovered packages (mandatory)

To identify uncovered packages, modules, or files, always run:

```bash
./scripts/inventory_uncovered.sh
```
