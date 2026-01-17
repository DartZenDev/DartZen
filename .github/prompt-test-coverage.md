# **PROMPT: Write Tests for DartZen Package**

You are acting as a **test engineer** for the DartZen monorepo.

Your **primary and overriding goal** is to **increase test coverage** for the package **`PACKAGE_NAME`**, aiming for **100% coverage where realistically possible**, without violating DartZen architecture rules.

This is **not** a refactoring task, **not** a redesign task, and **not** a style exercise.
Your only mission is **writing correct, maintainable tests** that increase coverage.

---

## **1\. Mandatory reading (DO THIS FIRST)**

Before writing or changing anything, you **must read and follow** the rules and principles described in **all** of the following documents:

- `.github/copilot-instructions.md`
- `README.md` (root of the monorepo)
- `docs/zen_architecture.md`
- `docs/gcp_native.md`
- `docs/packages_overview.md`
- `docs/server_runtime.md`
- `docs/development_workflow.md`
- `docs/versioning_and_releases.md`
- `docs/execution_model.md`

Additionally, **before starting work**, read and respect:

- `/docs/coverage_model.md`

These documents override any default assumptions you may have.

---

## **2\. Scope and constraints (ABSOLUTE RULES)**

- ❌ **DO NOT modify package source files**
- ❌ **DO NOT refactor production code**
- ❌ **DO NOT change public APIs**
- ❌ **DO NOT add test-only behavior to production code unless explicitly allowed**
- ❌ **DO NOT add comments unless they are necessary to explain non-obvious test intent**

If you believe a change to production code is required:

- STOP
- ASK FIRST
- DO NOT implement the change
- Revert any accidental modifications immediately

Look at **neighboring packages’ tests** to understand what is allowed and what is forbidden.

---

## **3\. Allowed exceptions**

- `@visibleForTesting` **IS ALLOWED** for:
  - network adapters
  - infrastructure code
  - environment or client injection
    Example reference:
  - `packages/dartzen_storage/lib/src/gcs_storage_reader.dart`
- Prefer **mocktail** for mocking.
  Example reference:
  - `packages/dartzen_storage/test/gcs_storage_reader_more_test.dart`

---

## **4\. Testing strategy requirements**

- Prefer **behavioral testing** over implementation testing
- Test through **public APIs** whenever possible
- Private logic should only be tested indirectly, unless infrastructure constraints require hooks
- Infrastructure and adapter code may use dependency injection for testability
- Tests must be deterministic and CI-safe

## Environment, runtime flags and recommended approach

- Tests **MUST** respect and rely on `DZ_ENV` and `DZ_PLATFORM` to exercise
  environment-specific code paths. CI and local validation run two test
  passes per package (`DZ_ENV=dev` and `DZ_ENV=prd`) and merge coverage from
  both runs.
- Prefer dependency injection and keep
  test-only helpers inside `test/` or dev-only libraries.
- How CI/local test runs work (example invocations):

  - Flutter package (example):

    ```bash
    # PRD run
    flutter test --dart-define=DZ_ENV=prd --dart-define=DZ_PLATFORM=macos --coverage

    # DEV run
    flutter test --dart-define=DZ_ENV=dev --dart-define=DZ_PLATFORM=macos --coverage
    ```

  - Pure Dart package (example):

    ```bash
    # PRD run
    dart test --define=DZ_ENV=prd --define=DZ_PLATFORM=linux --coverage=coverage

    # DEV run
    dart test --define=DZ_ENV=dev --define=DZ_PLATFORM=linux --coverage=coverage
    ```

- Practical recommendations:
  - Prefer dependency injection (DI) for test hooks in packages: accept
    `transport`, `socketFactory`, connector, or similar parameters so tests
    can inject fakes that live in `test/` and are never imported from
    `lib/`.
  - Keep test-only wiring inside `test/` or dev-only libraries so production
    builds remain tree-shakeable without global compile-time flags.
  - Run both `DZ_ENV=dev` and `DZ_ENV=prd` passes and collect coverage from
    each; the CI and compute scripts merge the resulting artifacts.
  - Group related tests into test suites within a single test file per package. Avoid splitting tests for the same production file across multiple test files.

## Test hooks and guidance (CLARIFICATION)

- Use DI and keep test helpers under
  `test/` or dev-only libraries so production artifacts are unaffected.
- If a package contains code that absolutely must be excluded from release
  bundles, use proper compile-time constants locally and ensure any such
  usage is limited and well-documented; prefer DI whenever possible.
- Never implement runtime switches that attempt to toggle compile-time
  behavior — these defeat tree-shaking and can leak test-only code into
  production builds.

---

## **5\. Coverage workflow (STRICT, STEP-BY-STEP)**

You must follow this loop **for each file** in the package:

1. Add tests for **one file at a time**
2. After finishing tests for that file:
   - Run analyzer and ensure **zero lint errors** like `melos exec --scope="PACKAGE_NAME" -- "dart analyze ."`
   - Run tests for that file and ensure they pass
3. Run **global package tests**
4. Verify that **coverage percentage increased**
   - If coverage did NOT increase:
     - Stop
     - Investigate why
     - Add or adjust tests until coverage increases
5. If tests pass and coverage increased:
   - Update `TEST_COVERAGE_PLAN.md`
6. Move to the **next file**
7. Repeat until **maximum achievable coverage** is reached

Coverage increase is **not optional**.
If coverage cannot be increased for a specific file, you must clearly justify why.

## Coverage and inventory verification (MANDATORY)

- After writing and running tests, the assistant MUST execute:
  `scripts/inventory_uncovered.sh`
- This script is the single source of truth for identifying uncovered packages, modules, or features.
- The assistant MUST:
  - review the output of this script
  - use it to decide what to cover next
- The assistant MUST NOT:
  - assume coverage completeness
  - rely on intuition or indirect signals
  - claim coverage without referencing this script’s results

---

## **6\. Running tests (IMPORTANT)**

❌ **DO NOT** run tests like this:

`dart test packages/PACKAGE_NAME`

✅ **ALWAYS** follow `pubspec.yaml` and run both environment passes:

- Check the `test` script to see how tests are expected to run
- Check `test:matrix` to understand how **maximum coverage** is validated

Correct example (adjust scope if needed):

`melos exec --scope="PACKAGE_NAME" -- \
  "dart --define=DZ_ENV=dev --define=DZ_PLATFORM=linux test --coverage=coverage"`

`melos exec --scope="PACKAGE_NAME" -- \
  "dart --define=DZ_ENV=prd --define=DZ_PLATFORM=linux test --coverage=coverage"`

You must run both `DZ_ENV=dev` and `DZ_ENV=prd` passes and collect coverage
from each. CI will convert/merge per-run artifacts into per-package `lcov_dev`/
`lcov_prd` files and then compute aggregated coverage.

- Use `dart` or `flutter` as appropriate for the package.
- Tests must set an explicit `DZ_ENV` and `DZ_PLATFORM` for each run.
- Tests that rely on implicit defaults or assume production values are invalid.

---

## **7\. Quality gates (NON-NEGOTIABLE)**

- `melos analyze` must pass with **zero issues**
- All tests must pass locally
- Coverage must **numerically increase**
- Tests must align with existing patterns in the monorepo
- No speculative or unused tests

---

## **8\. Final instruction**

The final response MUST explicitly reference the results of `scripts/inventory_uncovered.sh`.

Your **only success metric** is:

“Test coverage for THIS PACKAGE is higher than before, tests are clean, and all DartZen rules are respected.”

Proceed carefully, file by file, and treat coverage as a **measured, verified outcome**, not an assumption.

Start now.
