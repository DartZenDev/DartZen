# Infrastructure Philosophy

This document defines the philosophy, boundaries, and architectural role of the Infrastructure layer in the DartZen framework.

## 🏁 Introduction

The Infrastructure layer in DartZen serves as the execution layer for domain intent. While the Domain layer defines what should happen and the Contract layer defines how that intent is communicated, the Infrastructure layer is responsible for the actual execution against physical systems. It is the realm of side effects, external dependencies, and physical constraints. Its primary goal is to hide these complexities from the rest of the application, ensuring that business logic remains pure, deterministic, and testable.

## 🏗 Layer Boundaries

Infrastructure has a clear and rigid boundary. It is an implementation-only layer that operates strictly behind interfaces defined by the domain.

### Responsibilities
*   **Fulfillment**: Implementing repository, service, and client interfaces defined by the Domain layer.
*   **Resource Management**: Managing database connections, pooling, transactions, and persistence lifecycle.
*   **External Integration**: Orchestrating communication with external APIs, third-party services, and legacy systems.
*   **Cross-Cutting Concerns**: Implementing concrete sinks for caching, logging, and observability.
*   **I/O Operations**: Handling filesystem access, transient storage, and low-level network communication.

### Explicit Non-Responsibilities
*   **Policy Enforcement**: Infrastructure must not contain logic that determines business outcomes or enforces domain rules.
*   **Data Validation**: Semantic validation is the responsibility of Safe Value Objects; infrastructure assumes incoming domain objects are already valid.
*   **Meaning Definition**: Infrastructure does not define what an entity is; it only knows how to store and retrieve its representation.
*   **Access Control**: Orchestration of permissions and user roles belongs to the Domain layer.

## 🔃 Infrastructure as an Adapter

In DartZen, infrastructure is strictly an adapter. It implements "ports" defined by higher layers, ensuring the core application is decoupled from specific database drivers, cloud providers, or networking libraries.

Infrastructure code translates domain-level requests into the dialect of external systems (e.g., SQL dialects, specific REST structures, or binary protocols) and maps the results back into domain entities or result types. This adaptation must be lossless regarding meaning but entirely opaque regarding implementation. The domain should remain unaware of whether it is interacting with a local SQLite instance, a remote NoSQL cluster, or an in-memory mock during testing.

## 🎯 Caching Philosophy

Caching is treated as a transient performance optimization, never as a primary source of truth or a mechanism for critical state management.

*   **Optimization Only**: The system must remain fully functional and semantically correct if the cache is bypassed, cleared, or unavailable.
*   **No Logic in Cache**: Caching layers must not contain business logic or decision-making capabilities. They are passive mirrors of primary data.
*   **Transparency and Neutrality**: The domain should not be forced to provide "cache hints." The infrastructure decides if and how to cache based on its own configuration.
*   **Failure Resilience**: The failure of a cache operation—whether a miss, timeout, or corruption—must not change the outcome of a domain operation. Infrastructure must handle cache errors transparently, falling back to the source of truth without notifying the caller.

## 📅 Background Jobs & Schedulers

Background execution is managed at the infrastructure level to ensure operational isolation and system reliability.

*   **Isolation of Side Effects**: Tasks executed in the background must not leak their state or resource usage into the primary request-response cycle.
*   **Idempotency Mechanisms**: Infrastructure is responsible for provided technical idempotency (e.g., unique constraint handling or distributed locks) required to ensure that retriable jobs do not violate domain integrity.
*   **Separation of Concerns**: The domain schedules a conceptual task; the infrastructure decides how to queue, retry, and monitor that task using specific technologies (e.g., pub/sub, cron, or task queues).

## 🤖 External Services

Managed services, such as identity providers, communication gateways, and cloud storage, are contained within the infrastructure layer.

*   **Managed Replaceability**: Every external service is accessed through a domain-defined interface. This allows for replacing one provider with another by only modifying the infrastructure implementation, leaving the domain and contract layers untouched.
*   **SDK Containment**: Third-party SDKs and client libraries are strictly confined to the infrastructure layer. They must never leak into the signatures of domain services, contract models, or application logic.

## 📝 Observability & Logging

Infrastructure provides the plumbing for application awareness, health monitoring, and auditability.

*   **Signal Processing**: The application emits high-level semantic events; the infrastructure layer determines how these events are formatted, buffered, and exported to external systems.
*   **Decoupled Recording**: The Domain indicates that an event occurred. The Infrastructure layer decides if that event is recorded as a structured log entry, a metric increment, or a trace span.
*   **Sanitization and Privacy**: Infrastructure is responsible for ensuring that sensitive data defined by the domain is masked or stripped before being exported to external observability sinks.

## 🛠 Failure Semantics

The infrastructure layer is the primary interceptor and translator of physical failures. It converts the "noise" of hardware and network instability into the "meaning" of the domain.

*   **Exception Capturing**: Low-level exceptions (e.g., timeouts, socket errors, connection resets) must be caught at the infrastructure boundary and never allowed to propagate into the domain.
*   **Mapping to Results**: Physical failures are mapped to semantic error codes defined in the contract.
*   **Contextual Enrichment**: While the domain receives a clean error code, the infrastructure layer is responsible for logging the low-level details (stack traces, raw error messages) to facilitate debugging and monitoring.

## 🛑 Non-Goals

To maintain architectural purity, the Infrastructure layer explicitly avoids the following:

*   **Storing Business Knowledge**: Infrastructure will not contain logic that defines the "why" of an operation.
*   **Leaking Abstractions**: Database-specific concepts, such as table names, SQL hints, or HTTP status codes, will not be exposed to higher layers.
*   **Bypassing the Contract**: Infrastructure will not create "backdoor" communication paths that circumvent the official `ZenResult` or `BaseResponse` models.
*   **Technology Over-Elevation**: It will not implement complex wrappers for standard tools unless the wrapper directly facilitates the implementation of a domain interface.
