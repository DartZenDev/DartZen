# ☁️ GCP-Native Approach

DartZen is **GCP-native by design**.

Google Cloud Platform and Firebase are not treated as interchangeable infrastructure providers.
They are foundational parts of the DartZen system.

This document explains what “GCP-native” means in practice and why this choice is intentional.

## GCP Is Not “Infrastructure”

In DartZen, GCP is not an abstracted layer hidden behind interfaces.

- Firestore is a real database, not a replaceable persistence backend
- Firebase Authentication is a real identity system, not an adapter
- Cloud Storage is real file storage, not a generic blob service
- Gemini and Vertex AI are real AI services, not pluggable providers

DartZen does not pretend these services could be swapped without consequences.

They are part of the product’s reality.

## Why GCP-Native

The decision to build DartZen on GCP is driven by clarity and focus:

- Dart and Flutter are Google technologies
- Firebase and GCP provide first-class integration
- Tooling, SDKs, and emulators are mature and well supported
- The ecosystem is cohesive across client, server, and infrastructure

Optimizing for one strong ecosystem results in:

- simpler code
- fewer abstractions
- better developer experience
- fewer production surprises

## Firebase as a First-Class Runtime

Firebase is treated as a **runtime environment**, not just a collection of APIs.

DartZen relies on Firebase for:

- Authentication and identity lifecycle
- Firestore as the primary data store
- Local development via emulators
- Environment parity between development and production

Firebase is not wrapped to look generic.
It is used directly, consistently, and explicitly.

## Firestore Usage Philosophy

Firestore is accessed through shared utilities, not architectural layers.

DartZen:

- does not introduce repositories
- does not separate read and write models
- does not hide Firestore semantics

Instead:

- Firestore behavior is embraced
- snapshots, collections, and transactions are used as-is
- shared utilities exist only to reduce duplication and improve consistency

If Firestore behaves a certain way, DartZen reflects that behavior rather than masking it.

## Local Development with Emulators

Local development should behave like production, just without risk.

DartZen supports:

- Firestore Emulator
- Firebase Auth Emulator
- Cloud Storage Emulator (where applicable)

Environment detection is explicit:

- if emulator environment variables are present, DartZen connects to emulators
- otherwise, it connects to production services

There is no special “dev architecture”.
There is only one system running in different environments.

## Caching and Acceleration

Caching is treated as an optimization, not a foundational dependency.

- Production uses GCP Memorystore where appropriate
- Development may use in-memory caching or local Redis
- Cache behavior is explicit and environment-driven

The system remains correct without cache.
Cache exists only to make it faster.

## AI as a Native Capability

AI in DartZen is not a plugin.

Gemini and Vertex AI are integrated as native capabilities:

- for inference
- for content generation
- for intelligent workflows

There is no attempt to normalize or abstract AI providers.
DartZen uses the APIs that exist and exposes them honestly.

## No Multi-Cloud, No Illusions

DartZen does not aim to be multi-cloud.

Supporting multiple cloud providers would require:

- abstraction layers
- lowest-common-denominator APIs
- increased cognitive load

Zen Architecture values **focus over optionality**.

If your product is built on GCP, DartZen helps you do it well.
If it is not, DartZen is not the right tool.

## Summary

Being GCP-native means:

- real services, not abstracted concepts
- explicit dependencies
- environment parity
- fewer layers
- fewer surprises

DartZen embraces the ecosystem it lives in instead of fighting it.

This is not a compromise.
It is a design choice.
