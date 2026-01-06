# Test Coverage Plan for DartZen Monorepo

## Goal

- Produce deterministic, per-package coverage artifacts for every matrix cell and compute an aggregate coverage report.

## Coverage artifact layout

- Per-run coverage directories: `packages/<pkg>/coverage/coverage_<env>_<platform>_<type>/test/*.vm.json` or Flutter's `coverage` contents moved into that directory.
- Per-package LCOV outputs produced by CI: `packages/<pkg>/coverage/lcov_prd.info` and `packages/<pkg>/coverage/lcov_dev.info`.

## Matrix

- Environments: `dev`, `prd`
- Platforms: `web`, `linux`, `android` (Dart runs). Flutter web tests are compiled with `--platform=chrome` so conditional imports use `dart.library.html`.

## CI flow summary

1. `melos run test:matrix` produces per-run coverage under `packages/<pkg>/coverage/coverage_*`.
2. CI converts each per-run `vm.json` to per-run LCOV, merges them into `lcov_prd.info` and `lcov_dev.info` per package.
3. Upload per-package LCOV files to Codecov.
4. `./scripts/compute_local_coverage.sh` can be run locally to replicate CI conversion and compute AGGREGATE.

## Actions

- Ensure all `flutter test` invocations that target web use `--platform=chrome` and pass `--dart-define=DZ_PLATFORM=web`.
- Ensure Dart test runs write coverage into `coverage/coverage_<env>_<platform>_dart`.
- Remove VM JSON artifacts after conversion to avoid stale overwrites.

## Next steps

1. Run full test matrix and verify per-run coverage directories are created under each package's `coverage/` folder. (Completed locally via `melos run test:matrix`.)
2. Verify CI converts per-run coverage into `lcov_prd.info` / `lcov_dev.info` and uploads to Codecov. (Confirmed: CI conversion logic mirrors local script; adjusted workflow to include `apps/*/*` coverage conversion and upload.)
3. Triage any remaining failing tests (e.g., web/native conditional import mismatches) by either adding web implementations or skipping tests for unsupported platforms.
4. Ensure workspace packages are listed in root `pubspec.yaml` and that any package requiring workspace resolution includes `resolution: workspace` in its `pubspec.yaml`. (Added `packages/dartzen_server` to workspace and set `resolution: workspace`.)

## Recent progress (2026-01-05)

- Completed a full local matrix run (dev/prd × web, linux, android) and converted per-run VM JSON to LCOV via `./scripts/compute_local_coverage.sh`.
- `scripts/inventory_uncovered.sh` produced `scripts/coverage_uncovered.csv` with per-package uncovered totals.

### Aggregated results (local run 2026-01-05)

```
Package                                     Covered      Total        Pct
-------                                     -------      -----        ---
dartzen_localization                            292        300     97.33%
dartzen_identity                                580        614     94.46%
dartzen_storage                                 228        244     93.44%
dartzen_cache                                   248        266     93.23%
ZenDemo                                         251        274     91.61%
dartzen_core                                    385        438     87.90%
dartzen_server                                  160        230     69.57%
dartzen_firestore                               450        676     66.57%
dartzen_transport                               568        902     62.97%
dartzen_ui_identity                             278        508     54.72%
dartzen_ui_navigation                            52        113     46.02%

AGGREGATE                                      3492       4565     76.50%

LOCAL_COVERAGE=76.50
```

### Coverage review & remaining work (2026-01-05)

Summary: the repo aggregate improved to **76.50%**. To reach 100% overall every package must be brought to 100% coverage; the table below shows the current deficits (lines uncovered = Total - Covered).

- `dartzen_localization`: missing 8 lines — small, high-priority (easy fixes / tests).
- `dartzen_identity`: missing 34 lines — already at 94.46%; targeted tests (repository + a few model branches) will close this quickly.
- `dartzen_storage`: missing 16 lines — small, prioritize next.
- `dartzen_cache`: missing 18 lines — small.
- `ZenDemo`: missing 23 lines — app-level tests; medium effort.
- `dartzen_core`: missing 53 lines — medium effort; core utilities and error branches.
- `dartzen_server`: missing 70 lines — server integration & more complex flows.
- `dartzen_firestore`: missing 226 lines — significant; Firestore client and REST branches need more tests/mocks.
- `dartzen_transport`: missing 334 lines — largest gap; transport layer has many network/serialization branches to exercise.
- `dartzen_ui_identity`: missing 230 lines — UI-heavy; widget tests, platform variants and mocks required.
- `dartzen_ui_navigation`: missing 61 lines — UI/navigation widget tests.

Recommended priority to maximize ROI and close aggregate gap quickly:

1. Small packages with few uncovered lines: `dartzen_localization`, `dartzen_identity`, `dartzen_storage`, `dartzen_cache` — expect 1–2 days total to reach ~100% for these four.
2. `ZenDemo` and `dartzen_core` — medium effort (2–4 days); focus on uncovered utility branches and app tests.
3. `dartzen_server`, `dartzen_firestore` — larger effort (several days to a few weeks), needs more integration-mock work.
4. UI packages: `dartzen_ui_identity`, `dartzen_ui_navigation`, `dartzen_transport` — highest effort due to widget/integration tests and platform matrix; schedule these last or parallelize across engineers.

Actionable next steps (short term):

- Implement targeted tests for `packages/dartzen_identity` (we can close ~34 missing lines quickly). Priority: repository error branches then model edge-cases.
- Close `dartzen_localization`'s remaining 8 lines (small unit/IO test adjustments).
- Re-run matrix and recompute coverage; update `scripts/coverage_uncovered.csv` and iterate.

These recommendations assume existing test harnesses and mocking utilities are reused. If you want, I can begin with the `dartzen_identity` targeted tests now and drive the next local matrix run.

### Code & test changes applied during triage

- CI: `.github/workflows/codecov.yml` — made coverage-artifact assertion robust (use `find`) and include `apps/*/*` conversion/upload.
- Workspace: root `pubspec.yaml` — added `packages/dartzen_server`.
- Package manifest: `packages/dartzen_server/pubspec.yaml` — set `resolution: workspace`.
- Tests: `packages/dartzen_localization` IO tests — skip on web using `kIsWeb` to avoid `dart:io` failures in web/JS test runs.

These changes were validated locally by running the matrix and re-running affected packages' web/PRD tests.

_This plan will be kept in sync with the repository scripts and CI actions._
