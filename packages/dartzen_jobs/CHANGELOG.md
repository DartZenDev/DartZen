## 0.0.2

- **BREAKING**: Removed `ZenJobs.trigger()` and `ZenJobs.handleRequest()` stub methods that always threw `MissingDescriptorException`. These methods created a false API contract. Job execution is the responsibility of `ZenJobsExecutor` implementations only.
- Updated `ZenJobs.register()` docstring to clarify registry-only responsibility.
- **Enhancement**: Extracted complex Firestore queries in `JobStore` into dedicated helper method `_buildEnabledPeriodicJobsQuery()` for improved maintainability.
- **Enhancement**: Created new `JobValidator` utility class (lib/src/job_validator.dart) that centralizes job validation logic:
  - `validateJobExists(jobId, registry)` - Validates job descriptor registration
  - `validateHandlerExists(jobId)` - Validates handler registration
  - `isEnabledForExecution(config, now)` - Checks job eligibility for execution
  - `validateDependencies(depIds, configsById)` - Validates dependency satisfaction
- **Refactoring**: `JobRunner.execute()` now uses `JobValidator` for cleaner, more testable validation logic.
- **Documentation**: Added explicit retry logic semantics to `JobRunner.execute()` docstring explaining attempt numbering (1-based), currentRetries vs attempt distinction, automatic retry behavior, and maxRetries comparison.
- **Documentation**: Updated `docs/execution_model.md` to clarify that Zone-based service injection (Zone.current keys) is future work, not currently implemented. Added TODO comment in `JobRunner` for future Zone implementation.
- **Testing**: Added comprehensive test suite for `JobValidator` in test/job_validator_test.dart covering all validation scenarios.
- **Testing**: Added test for Firestore query structure validation in job_store_test.dart.

## 0.0.1

- Initial release of `dartzen_jobs`.
- Unified model for Endpoint, Scheduled, and Periodic jobs.
- Firestore-backed `JobStore` for runtime configuration and state tracking.
- `MasterJob` for cost-efficient batching of periodic jobs.
- `CloudTasksAdapter` for reliable event-driven execution.
- Integrated telemetry and structured logging.
- Simulation mode for local development.
