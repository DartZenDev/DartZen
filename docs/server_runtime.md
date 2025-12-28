# **Server Runtime**

## **DartZen Server Runtime**

The DartZen server is a **GCP-native runtime** built on top of **Shelf**, designed for clarity, performance, and explicit behavior.

It is not a framework, not an abstraction layer over cloud services, and not a place for domain logic.  
It is an **execution environment** that wires together infrastructure, configuration, and lifecycle in a predictable and inspectable way.

---

## **Core Principles**

### **1\. Runtime, Not Framework**

The DartZen server runtime does not impose architectural patterns, controllers, or magic conventions.

* No hidden dependency injection  
* No auto-discovery  
* No reflection-based behavior  
* No implicit middleware chains

Everything is explicit, composable, and visible in code.

Shelf is used as a **minimal HTTP kernel**, not as an opinionated framework.

---

### **2\. GCP-Native by Design**

The runtime is designed specifically for Google Cloud Platform:

* Cloud Run (HTTP services)  
* Cloud Run Jobs (background and scheduled execution)  
* Firestore  
* Cloud Storage  
* Memorystore  
* Vertex AI / Gemini  
* Google Cloud logging and metrics

This is not a “cloud-agnostic” abstraction.  
It is a deliberate alignment with GCP primitives.

---

### **3\. Explicit Lifecycle**

The server runtime defines a clear and predictable lifecycle:

* Process startup  
* Configuration loading  
* Dependency initialization  
* Middleware wiring  
* Request handling  
* Graceful shutdown

There is no hidden bootstrapping logic.  
If something happens, it happens because it is written.

---

### **4\. Clear Application Boundary**

The server runtime is an **application boundary**, not a domain container.

* Domain logic lives in feature packages  
* Infrastructure adapters live in dedicated packages  
* The runtime only wires them together

The server does not “own” the domain.  
It hosts it.

---

## **Shelf as the Runtime Kernel**

Shelf is used for what it does best:

* HTTP request/response handling  
* Middleware composition  
* Streaming  
* Performance with minimal overhead

DartZen does not wrap Shelf into another framework.  
Instead, it provides **clear patterns** for assembling a Shelf-based application.

---

## **Configuration and Environment**

The runtime assumes:

* Configuration via environment variables  
* Explicit config parsing and validation  
* No global mutable state  
* No hidden defaults

If a value is required, it must be provided.  
If a value is optional, its default must be explicit.

---

## **Observability and Telemetry**

The runtime is designed to integrate naturally with:

* Structured logging  
* Tracing  
* Metrics  
* Event emission

Observability is not an afterthought and not injected magically.  
It is wired explicitly through middleware and services.

---

## **Background Jobs**

The server runtime supports:

* HTTP services  
* Background jobs  
* Scheduled execution

Jobs are not a special case or a different architecture.  
They use the same runtime principles, configuration, and infrastructure wiring.

---

## **What the Runtime Is Not**

The DartZen server runtime is **not**:

* A full-stack framework  
* A domain container  
* A microservice generator  
* A dependency injection framework  
* A cloud abstraction layer

Its role is narrow, intentional, and constrained.

---

## **Relationship to Other Packages**

The server runtime works in coordination with:

* `dartzen_server` — application runtime assembly  
* `dartzen_firestore` — persistence utilities  
* `dartzen_cache` — caching  
* `dartzen_storage` — blob and static storage  
* `dartzen_jobs` — background execution  
* `dartzen_telemetry` — events and analytics  
* Feature packages (identity, payments, AI, etc.)

Each package has a single responsibility.  
The runtime composes them without owning them.

---

## **Summary**

The DartZen server runtime is:

* Explicit instead of magical  
* GCP-native instead of abstract  
* Minimal instead of layered  
* Predictable instead of clever

It exists to make server behavior **obvious**, **testable**, and **operationally honest**.

