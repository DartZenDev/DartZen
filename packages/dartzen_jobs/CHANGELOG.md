## 0.0.1

* Initial release of `dartzen_jobs`.
* Unified model for Endpoint, Scheduled, and Periodic jobs.
* Firestore-backed `JobStore` for runtime configuration and state tracking.
* `MasterJob` for cost-efficient batching of periodic jobs.
* `CloudTasksAdapter` for reliable event-driven execution.
* Integrated telemetry and structured logging.
* Simulation mode for local development.
