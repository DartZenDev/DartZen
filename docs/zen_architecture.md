# 🧘 Zen Architecture

Zen Architecture is the foundational design philosophy behind DartZen.

It is not a framework, not a pattern catalog, and not a layered model.
Zen Architecture is a set of **constraints, defaults, and decisions** that shape how DartZen is built and how it evolves over time.

The goal is simple:
**reduce cognitive load while staying honest about the real system you are building.**

## What Zen Architecture Is Not

Zen Architecture explicitly rejects the following ideas:

- No Clean Architecture
- No Hexagonal / Onion / Ports & Adapters
- No Domain-Driven Design layers
- No artificial separation into “domain”, “contract”, and “infrastructure”
- No abstractions created “just in case”

These approaches are powerful in enterprise environments, but they add ceremony, indirection, and vocabulary that DartZen intentionally avoids.

DartZen optimizes for **clarity, speed, and product reality**, not architectural purity.

## Core Principles

### 1. Product-First, Not Architecture-First

Zen Architecture starts with the product, not with diagrams.

Packages represent **product capabilities**, not architectural layers.
If something exists because the product needs it, it belongs in the system.
If something exists only to satisfy an architectural idea, it does not.

### 2. See With Your Eyes (Zero Magic)

DartZen avoids hidden behavior.

- No code generation that obscures logic
- No implicit wiring
- No runtime magic

What the system does should be visible by reading the code.
If something happens, you should be able to find it.

Predictability is valued more than cleverness.

### 3. Real Dependencies Are First-Class

Zen Architecture does not pretend that external systems are optional.

DartZen is **intentionally built on top of Google Cloud Platform and Firebase**.

- Firestore is not abstracted away
- Firebase Authentication is not hidden
- GCP services are treated as real, stable dependencies

This is not a limitation.
It is a deliberate trade-off for simplicity, performance, and DX.

### 4. No Artificial Purity

There is no concept of a “pure domain” in Zen Architecture.

Business logic, persistence logic, and integration logic may live close to each other **when that reflects reality**.

The goal is not purity.
The goal is **coherence**.

### 5. Utilities Over Abstractions

Zen Architecture favors:

- small utility packages
- explicit helpers
- boring, readable APIs

over:

- deep inheritance trees
- generic interfaces
- swap-ready abstractions

If a dependency is not meant to be swapped, it should not pretend to be.

### 6. Environment Is Explicit

Zen Architecture embraces environment differences instead of hiding them.

- Development uses emulators where available
- Production uses real GCP services
- Configuration is driven by environment variables
- No “mock world” that behaves unlike production

What runs locally should behave like production, just cheaper and safer.

## Packages as Capabilities

In Zen Architecture:

- A package answers the question:
  **“What capability does this give to the product?”**

Examples:

- Identity
- Storage
- Payments
- Telemetry
- Jobs
- AI

Packages are not:

- layers
- tiers
- technical boundaries

They are **capabilities with clear responsibility**.

## Client and Server Are One System

Zen Architecture does not treat client and server as separate worlds.

They are:

- developed together
- versioned together
- reasoned about together

Consistency between client and server matters more than theoretical separation.

## Why “Zen”

Zen Architecture is about removing noise.

- fewer concepts
- fewer files
- fewer indirections
- fewer decisions per line of code

This creates space for what matters:

- product logic
- user experience
- reliability
- long-term maintainability

Zen is not minimalism for its own sake.
Zen is **clarity through deliberate constraint**.

## Summary

Zen Architecture is:

- Product-driven
- GCP-native
- Explicit
- Boring in the right places
- Optimized for human understanding

If a design decision increases confusion, it is not Zen.
If it makes the system easier to reason about, it probably is.
