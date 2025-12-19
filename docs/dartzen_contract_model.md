# DartZen Contract Model

This document defines the architecture of truth in the DartZen framework. It specifies how clients and servers share meaning without relying on external schemas or code generation.

## 1. Core Philosophy

DartZen follows a **runtime-first, contract-as-code** approach. The contract is not a side effect of development; it is the source of truth.

*   **Shared Types**: Contracts are expressed as native Dart types shared between client and server.
*   **No Code Generation**: There is no intermediate step between defining a contract and using it.
*   **No Schema DSL**: The language of the implementation (Dart) is the language of the contract.
*   **Explicit Failure**: Success and failure are modeled as data, never as side effects.
*   **Control Flow**: Exceptions are reserved for catastrophic failures only. Business logic uses result types.

## 2. What Is a Contract

A contract in DartZen is the set of types and validation rules that define the interface between independent components.

### In-Contract
*   Message structures (Requests/Responses).
*   Result wrappers (`ZenResult`).
*   Error hierarchies and semantic codes.
*   Value objects with construction-time validation.
*   Type-safe constants used for identification.

### Out-of-Contract
*   Database schemas and persistence logic.
*   Authentication implementation details (tokens, cookies).
*   UI state or presentation logic.
*   Logging and observability implementations.
*   Transport-specific headers or status codes.

## 3. Contract Boundaries & Ownership

The contract exists in a dedicated layer that acts as a buffer between the internal logic of the server and the external world of the client.

### Ownership
The contract is a shared responsibility. While the server typically dictates the evolution of the contract, both sides must adhere to it strictly. The contract layer should reside in a package independent of both the core server implementation and the UI framework.

### Change Management
*   **Non-breaking changes**: Adding optional fields, adding new response codes (handled by default cases), or introducing new request types.
*   **Contract-breaking changes**: Removing fields, making optional fields required, changing field types, or altering the semantic meaning of existing fields.

### Versioning
Versioning is determined by the compatibility of the types. When a change forces an update to the shared contract types that is not backwards compatible at the source level, a new version of the contract package is required.

## 4. Request Model

Requests are modeled as immutable Dart classes or records. 

*   **Validation**: Requests must validate their own integrity during construction. A request object cannot exist in an invalid state.
*   **Data Constraints**: Requests should only contain data necessary for the operation. They must not carry implementation-specific metadata.
*   **Transport Mapping**: Requests remain unaware of their transport. Whether sent via HTTP POST or a WebSocket message, the request type remains identical.

## 5. Response Model

`BaseResponse` is the wire-level contract for the DartZen ecosystem. It is a stable carrier of meaning designed to be transport-agnostic.

### Responsibilities
*   **Carrier Role**: It acts as a universal container for any message payload.
*   **Status Clarity**: It provides an immediate, unambiguous indication of success or failure.
*   **Error Context**: It carries semantic error codes and human-readable messages across boundaries.

### Characteristics
*   **Wire-level stability**: The structure of `BaseResponse` rarely changes.
*   **Protocol-independent**: It is not an HTTP response and does not map 1:1 to HTTP status codes.
*   **Framework-agnostic**: It exists independently of any serialization format or networking library.

## 6. Result Model

The Result Model governs how logic returns values within a single process or across boundaries.

### ZenResult<T>
Operations do not throw; they return a `ZenResult`. This is a sealed union of `ZenSuccess` and `ZenFailure`.

### Why Exceptions are Forbidden
Exceptions are invisible in the type system. They create non-deterministic exit points in code. By using `ZenResult`, failures are promoted to first-class values that the compiler forces the developer to handle.

### Propagation
Failure propagation is explicit. A failure at the repository layer is wrapped in a `ZenResult`, passed to the service, and eventually mapped to a `BaseResponse`.

## 7. Error Semantics

Errors are not just strings; they are structured data.

*   **Error Codes**: Machine-readable strings (e.g., `NOT_FOUND_ERROR`) used for logic branching on the client.
*   **Localizable Messages**: Messages carry context but may be replaced by localized strings on the client using the error code as a key.
*   **Domain vs. Transport**: Domain errors (e.g., `INSUFFICIENT_FUNDS`) are part of the contract. Transport errors (e.g., `TIMEOUT`) are handled by the transport layer and mapped into the contract if they prevent contract fulfillment.

## 8. Safe Value Objects

Raw primitives (strings, ints) are forbidden for domain-significant data.

*   **Primitive Obsession**: A `String` should not represent an `Email`.
*   **Validation at Construction**: Value objects use factory constructors that return a `ZenResult`. If validation fails, the object is never created.
*   **Safety**: Once a value object exists, it is guaranteed to be valid according to the contract's rules.

## 9. Client–Server Symmetry

Because both sides use the same Dart types, the contract ensures perfect symmetry.

*   **Uniform Logic**: Validation logic written for a value object runs identically on the client (for immediate feedback) and on the server (for security).
*   **Shared Meaning**: When the server returns a `ZenFailure`, the client interprets it using the exact same type definitions, ensuring no "magic" mapping is required.

## 10. Transport Independence

The contract model is decoupled from the `dartzen_transport` implementation.

*   **Isolation**: The contract layer has no dependency on `dart:io`, `dart:html`, or specific HTTP packages.
*   **Adaptability**: The same contract can be served via JSON/REST, MessagePack/RPC, or binary streams without modification to the contract types.
*   **Codec Agnostic**: The contract defines the *structure* of data; the transport determines the *encoding* and *delivery mechanism*.
