# DartZen

[![GitHub](https://img.shields.io/badge/GitHub-DartZenDev-blue.svg)](https://github.com/DartZenDev/DartZen)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**The opinionated, scalable core starter kit for Dart & Flutter.**

Minimalist architecture, domain-first approach, and developer zen.

## 🎯 Philosophy

DartZen embraces **minimalism**, **scalability**, and **developer zen**. Built on the principle that less is more, it provides a clean foundation for building production-ready Dart and Flutter applications without unnecessary complexity.

## 📖 Documentation

- [Zen Architecture](docs/zen_architecture.md): Explains the core principles behind DartZen: product-first design, minimal cognitive load, zero magic, and explicit integrations.
- [GCP-Native Approach](docs/gcp_native.md): Describes how DartZen is built around Google Cloud Platform and Firebase as first-class dependencies, not abstracted infrastructure.
- [Development Workflow](docs/development_workflow.md): How the monorepo is developed, tested, and maintained, including local development, emulators, and CI.
- [Local Development & Emulators](docs/local_development.md): How to run DartZen locally using Firebase and GCP emulators, environment variables, and provided scripts.
- [Packages Overview](docs/packages_overview.md): A high-level map of DartZen packages, their responsibilities, and how they are meant to be used together.
- [Server Runtime](docs/server_runtime.md): Defines the DartZen server as a GCP-native runtime built on Shelf, focused on clarity, performance, and explicit behavior.
- [Versioning and Releases](docs/versioning_and_releases.md): Explains independent package versioning, SemVer, and release strategy within the DartZen monorepo.

## 📦 Repository Structure

This is a **monorepo** managed with [Melos](https://melos.invertase.dev/), containing multiple Dart packages organized for maximum reusability and independent versioning.

```
dartzen/
├── packages/
│   ├── dartzen_core/       # Core primitives, contracts, and domain value objects
│   ├── ...
│   └── dartzen_navigation/ # Navigation widget for Flutter applications
├── apps/                   # Example applications (future)
├── melos.yaml              # Monorepo configuration
└── CONTRIBUTING.md         # Contribution guidelines
```

### Packages

- **`dartzen_core`**: Core primitives, shared contracts, result types, and domain value objects — the foundation for all other packages. Does **not** include infrastructure concerns.
- **`dartzen_localization`**: Foundational localization package for the DartZen ecosystem.
- **`dartzen_firestore`**: Firestore operations and converters for the DartZen ecosystem.
- **`dartzen_navigation`**: Unified, adaptive navigation layer for DartZen applications with platform-specific optimizations.
- **`dartzen_transport`**: DartZen transport layer for serialization, codec selection, WebSocket communication, HTTP client, and Shelf middleware.
- **`dartzen_cache`**: Simple, explicit, and predictable caching for the DartZen ecosystem with in-memory and GCP Memorystore backends.
- **`dartzen_server`**: DartZen server application framework — defines application lifecycle, middleware, routing, and configuration.
- **`dartzen_storage`**: Google Cloud Storage reader for the DartZen ecosystem.
- **`dartzen_identity`**: Identity service for DartZen — provides a unified interface for identity management, including authentication, authorization, and user management.
- **`dartzen_ui_identity`**: Cross-platform, adaptive UI components and screens for DartZen Identity flows.

## 📄 License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.
