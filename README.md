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

- [DartZen Contract Model](docs/dartzen_contract_model.md) — Defines the shared contract and semantic language between client and server.
- [Development Workflow](docs/development_workflow.md) — Describes how the repository is developed, tested, and maintained.
- [Versioning and Releases](docs/versioning_and_releases.md) — Explains how independent versioning and SemVer are applied in DartZen.
- [Infrastructure Philosophy](docs/infrastructure_philosophy.md) — Clarifies how DartZen interacts with physical systems while keeping the domain pure.
- [Identity Model Philosophy](docs/identity_model_philosophy.md) — Establishes identity as a stable domain concept, independent of authentication details.

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
- **`dartzen_client_transport`**: Minimal HTTP client wrapper for DartZen transport layer.
- **`dartzen_localization`**: Foundational localization package for the DartZen ecosystem.
- **`dartzen_msgpack`**: Minimal MessagePack implementation for the DartZen ecosystem.
- **`dartzen_navigation`**: Unified, adaptive navigation layer for DartZen applications with platform-specific optimizations.
- **`dartzen_server_transport`**: Minimal Shelf middleware for DartZen transport layer.
- **`dartzen_transport`**: DartZen transport layer for serialization, codec selection, and WebSocket communication.

## 📄 License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.
