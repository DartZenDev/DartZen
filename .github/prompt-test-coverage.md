## **PROMPT: Write Tests for DartZen Package**

You are acting as a **test engineer** for the DartZen monorepo.

Your **primary and overriding goal** is to **increase test coverage** for the package **`PACKAGE_NAME`**, aiming for **100% coverage where realistically possible**, without violating DartZen architecture rules.

This is **not** a refactoring task, **not** a redesign task, and **not** a style exercise.
Your only mission is **writing correct, maintainable tests** that increase coverage.

---

### **1\. Mandatory reading (DO THIS FIRST)**

Before writing or changing anything, you **must read and follow** the rules and principles described in **all** of the following documents:

- `.github/copilot-instructions.md`
- `README.md` (root of the monorepo)
- `docs/zen_architecture.md`
- `docs/gcp_native.md`
- `docs/packages_overview.md`
- `docs/server_runtime.md`
- `docs/development_workflow.md`
- `docs/versioning_and_releases.md`

Additionally, **before starting work**, read and respect:

- `/TEST_COVERAGE_PLAN.md`
- `/docs/coverage_model.md`
- `.github/implementation-plan-template.md`

These documents override any default assumptions you may have.

---

### **2\. Scope and constraints (ABSOLUTE RULES)**

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

### **3\. Allowed exceptions**

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

### **4\. Testing strategy requirements**

- Prefer **behavioral testing** over implementation testing
- Test through **public APIs** whenever possible
- Private logic should only be tested indirectly, unless infrastructure constraints require hooks
- Infrastructure and adapter code may use dependency injection for testability
- Tests must be deterministic and CI-safe

#### Environment, compile-time & runtime flags

- Tests **MUST** respect and rely on the existing DartZen constants: `dzIsTest`, `dzIsPrd`, `DZ_ENV`, and `DZ_PLATFORM`.
- Tests **MUST NOT** introduce new global environment flags or platform switches.

- `dzIsTest` is a compile‑time constant. To enable test‑only branches that are safe to remove from release artifacts, compile tests with `DZ_IS_TEST=true` (see examples below). Do **not** implement a runtime override for `dzIsTest` — runtime toggles defeat compile‑time tree‑shaking and may leak test‑only code into production bundles.

- How to run tests with defines (examples):

  - Flutter package (preferred for packages that depend on Flutter):

    ```bash
    flutter test --dart-define=DZ_IS_TEST=true \
      --dart-define=DZ_ENV=dev --dart-define=DZ_PLATFORM=macos --coverage
    ```

  - NOTE: In this monorepo `dart test` (and invocations wrapped by `melos`) may not reliably recompile dependencies with new `--define` values; as a result, compile‑time flags such as `DZ_IS_TEST=true` can appear to be ignored and test code guarded by `dzIsTest` will be skipped. Because of this fragility, treat compile‑time defines as useful for CI or clean builds only, and prefer the DI approach described below for local and per‑package testing.

- Practical caveats and recommendations:
  - Because forcing defines across a dependency graph can be brittle and may not work reliably with the test runner in this repo, **prefer dependency injection (DI)** for test hooks in pure Dart packages: accept `transport`, `socketFactory`, or connector parameters in constructors so tests can inject fakes that live only in `test/`. Keeping fake implementations in `test/` (or dev-only libraries) and never importing them from `lib/` prevents test code from being included in release bundles.
  - If you do rely on compile‑time defines for CI, ensure CI performs a clean build or exports `DZ_IS_TEST=true` in the job environment so the entire graph is compiled with the define. Avoid relying on `dart test` passing a `--define` to already cached compiled dependencies.
  - Conditional imports **MUST NOT** be emulated using runtime flags; continue to use proper compile‑time defines and platform selectors.
  - Do not mock platform constants — run platform variants via `--platform` in the test matrix so the test runner uses the appropriate compiler/runtime.

- CI requirement: ensure CI job definitions either export `DZ_IS_TEST=true` or run test invocations with the required `--define` flags so that compile‑time test branches are exercised in CI.

### dzIsTest and test hooks (CLARIFICATION)

- `dzIsTest` is a compile-time constant and must remain so. Tests may use `--define=DZ_IS_TEST=true` during compilation to enable test-only branches, and production builds must never rely on a runtime override of this flag.
- Use `dzIsTest` to guard helpers or branches that must be omitted from release artifacts (for example, test-only factories or helpers). Placing such code behind `if (dzIsTest) { ... }` ensures the compiler can tree-shake it out of production bundles.
- For pure Dart packages where passing compile-time defines through the test runner can be brittle, prefer dependency injection for testability: accept `transport`, `socketFactory`, connector, or similar hooks in constructors so tests can inject fakes from `test/` code. Keeping fake implementations in `test/` (or dev-only libraries) and never importing them from `lib/` prevents test-only code from being included in release bundles.
- Do NOT add runtime switches that flip `dzIsTest` at runtime — this defeats compile-time tree-shaking and risks leaking test-only behavior into production bundles (especially relevant for web builds where bundle size and content are critical).


---

### **5\. Coverage workflow (STRICT, STEP-BY-STEP)**

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

#### Coverage and inventory verification (MANDATORY)

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

### **6\. Running tests (IMPORTANT)**

❌ **DO NOT** run tests like this:

`dart test packages/PACKAGE_NAME`

✅ **ALWAYS** follow `pubspec.yaml`:

- Check the `test` script to see how tests are expected to run
- Check `test:matrix` to understand how **maximum coverage** is validated

Correct example (adjust scope if needed):

`melos exec --scope="PACKAGE_NAME" -- \`
`"dart run \`
`--define=DZ_IS_TEST=true \`
`--define=DZ_ENV=dev \`
`--define=DZ_PLATFORM=linux \`
`test --coverage=coverage"`

You must respect all required `--define` flags.

Use `dart` or `flutter` as appropriate for the package.

- All tests MUST be executed with the correct DartZen environment flags.
- The test runner invocation MUST explicitly set:
  - `DZ_IS_TEST=true`
  - a non-production `DZ_ENV`
  - an explicit `DZ_PLATFORM`
- Tests that rely on implicit defaults or assume production values are invalid.

---

### **7\. Quality gates (NON-NEGOTIABLE)**

- `melos analyze` must pass with **zero issues**
- All tests must pass locally
- Coverage must **numerically increase**
- Tests must align with existing patterns in the monorepo
- No speculative or unused tests

---

### **8\. Final instruction**

The final response MUST explicitly reference the results of `scripts/inventory_uncovered.sh`.

Your **only success metric** is:

“Test coverage for THIS PACKAGE is higher than before, tests are clean, and all DartZen rules are respected.”

Proceed carefully, file by file, and treat coverage as a **measured, verified outcome**, not an assumption.

Start now.
