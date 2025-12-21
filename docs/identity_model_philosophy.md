# Identity Model Philosophy

This document defines the conceptual identity model used across the DartZen framework. It establishes the boundaries between identity as a domain concept and authentication as an infrastructure mechanism.

## 🏁 Introduction

In DartZen, identity is treated as a stable, first-class citizen of the Domain layer. While most frameworks conflate "who a user is" with "how they proved it," DartZen enforces a strict separation. Identity is the permanent anchor for authority, state, and ownership, whereas the mechanisms used to verify that identity are transient implementation details of the Infrastructure layer.

## 👤 What Is an Identity in DartZen

An identity is a unique, stable representation of a subject—be it a human user, a service, or an automated system. It is the primary key for all domain-level decisions.

*   **Stability**: Identity must persist across sessions, devices, and authentication method changes.
*   **Uniqueness**: Every subject in the ecosystem possesses exactly one identity within a given domain context.
*   **Agnosticism**: An identity does not imply a specific verification method. Whether a subject used a password, a biometric scan, or a hardware key, their identity remains the same.

## 🔐 Identity vs Authentication

The distinction between identity and authentication is the foundation of DartZen’s security architecture.

*   **Identity (Domain)**: Defines *who* the subject is. It is a semantic concept used to evaluate business rules, ownership, and permissions.
*   **Authentication (Infrastructure)**: Defines *that* the subject is who they claim to be. It involves checking credentials, validating tokens, and managing session lifetimes.

Authentication acts as the gatekeeper at the infrastructure boundary. Once a subject is successfully authenticated, the infrastructure maps the transient credential to a stable domain identity. The Domain layer never sees tokens, headers, or signatures; it only sees the validated identity.

## 💎 Identity as a Domain Primitive

Identity is not a primitive string or integer; it is a **Domain Primitive**.

*   **Type Safety**: Identity is passed through the system as a dedicated value object, protected by the same validation rules as any other domain concept.
*   **Contextual Integrity**: Identity flows across request boundaries and service calls as a structured object. The mechanics of this transfer are entirely infrastructure-defined. It carries its own validity, ensuring that downstream services can rely on the subject's identity without re-parsing infrastructure-specific metadata.
*   **Universal Understanding**: Because it is defined in the Domain layer, identity has the same meaning for a mobile client, a web dashboard, and a background worker.

## 🎭 Roles, Capabilities, and Authority

Authorization in DartZen is a logical evaluation of identity within a specific domain context.

*   **Roles**: High-level groupings of intent (e.g., `ADMIN`, `MEMBER`). Roles are domain-defined labels that simplify policy management.
*   **Capabilities**: Granular definitions of what an identity is permitted to do (e.g., `can_edit_document`, `can_invite_user`).
*   **Authority**: The final, evaluated decision of whether an identity can perform an action.

Authorization decisions belong to the Domain layer because they represent business logic. Infrastructure only provides the data (roles/permissions) required for the Domain to make these decisions.

## 🌐 External Identity Providers

DartZen is designed to be entirely agnostic of external identity providers (IdPs).

*   **Provider Isolation**: Integration with external identity providers (IdPs) is strictly contained within the Infrastructure layer.
*   **Mapping Layer**: Infrastructure is responsible for translating provider-specific identifiers (e.g., a UUID from a JWT) into the internal stable identity used by the domain.
*   **Vendor Lock-in Mitigation**: Switching from one IdP to another requires only an infrastructure-level update. The domain-level identity and all associated business logic remain unchanged.

## ⚠️ Failure Semantics

Failures in the identity lifecycle are categorized by where they occur and what they mean to the system.

*   **Authentication Failures (Infrastructure)**: These occur when a credential cannot be verified (e.g., `EXPIRED_TOKEN`, `INVALID_SIGNATURE`). These are handled by infrastructure and rarely reach the domain.
*   **Identity Failures (Domain)**: These occur when an identity is valid but unsuitable for the requested operation (e.g., `IDENTITY_REVOKED`, `IDENTITY_NOT_FOUND`).
*   **Authority Failures (Domain)**: These occur when an identity is known but lacks the necessary capabilities for an action (e.g., `INSUFFICIENT_PERMISSIONS`).

Regardless of the source, all failures are mapped to semantic `ZenResult` failures as defined in the Contract layer, ensuring the caller receives precise, actionable information without leaking infrastructure details.

## 🛑 Non-Goals

To maintain its architectural focus, the Identity Model Philosophy explicitly ignores the following:

*   **Credential Management**: We do not define how passwords should be hashed or where they should be stored.
*   **Login Orchestration**: We do not describe UI flows, multi-factor loops, or "Forgot Password" sequences.
*   **Token Lifecycle**: We do not specify token formats, rotation policies, or expiration durations.
*   **Transport Mechanics**: We do not define how identity is carried over HTTP, WebSockets, or gRPC (e.g., headers, cookies).
*   **Session State**: We do not manage session persistence or distributed cache synchronization for sessions.
