# Coverage aggregation

This repository includes a helper script to compute per-package and aggregate
coverage: `./scripts/compute_local_coverage.sh`.

- Run it from the repository root. It expects coverage artifacts under
  `packages/*/coverage`.
- The script prefers an existing `coverage/lcov.info` for a package when that
  file is newer than any `coverage/test/*.vm.json` artifacts. This prevents an
  older JSON-to-LCOV conversion from overwriting a fresh
  `flutter test --coverage` result.

To regenerate and include `dartzen_localization` coverage (example):

```bash
# from repo root
cd /path/to/DartZen
cd packages/dartzen_localization && flutter test --coverage
# then from repo root
./scripts/compute_local_coverage.sh
```

If you want to force re-conversion from VM JSON files, either remove the
package `coverage/lcov.info` or delete the `coverage/test` VM JSON files
before running the script.

## Canonical upload files and expected `melos` behavior

- CI uploads per-package, per-environment LCOV files: `packages/<pkg>/coverage/lcov_prd.info` and `packages/<pkg>/coverage/lcov_dev.info`.
- The repository's `melos run test:matrix` task should run the test matrix (PRD and DEV combinations and platforms) and produce coverage artifacts either as VM JSON under `packages/<pkg>/coverage/test/*.vm.json` or (for Flutter tests) directly as `packages/<pkg>/coverage/lcov.info`.
- The CI workflow converts VM JSON -> LCOV per-package into `lcov_prd.info` and `lcov_dev.info` and then uploads those files to Codecov. The compute script `./scripts/compute_local_coverage.sh` is a local/CI sanity tool that normalizes/merges these LCOVs and computes an aggregate percentage.

If your `melos run test:matrix` does not produce per-package coverage artifacts, the CI assertion step will fail; ensure `melos run test:matrix` is run from the repo root and that each package's test task writes coverage to its `coverage` directory.
