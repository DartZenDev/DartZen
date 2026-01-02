# **DartZen Packages Overview**

DartZen is organized into modular packages, each focused on a specific concern. Packages are designed to be **reusable**, **domain-agnostic where possible**, and **tightly integrated with Google Cloud Platform (GCP) and Firebase**.

No monoliths.  
No hidden coupling.  
No framework gravity.

This document provides a high-level overview of all approved DartZen packages and how they relate to each other.

---

## **Core & Foundations**

### **`dartzen_core`**

* **Purpose:** Core primitives, Result type, shared errors.  
* **Scope:** Minimal, fully independent foundation for all other packages.  
* **Notes:** No infrastructure, domain logic, or SDK dependencies.

### **`dartzen_firestore`**

* **Purpose:** Firestore utility toolkit for DartZen packages.  
* **Scope:**  
  * Client initialization and configuration  
  * Emulator vs production environment  
  * Typed document and collection helpers  
  * Batch and transaction helpers  
  * Converters, serializers  
  * Error normalization and lifecycle management  
* **Restrictions:** No domain models, Identity logic, or feature-specific queries. All other packages must use this package to access Firestore.

### **`dartzen_identity`**

* **Purpose:** Identity feature package.  
* **Scope:**  
  * Domain models for users, roles, and permissions  
  * Repositories using `dartzen_firestore`  
  * Lifecycle management of identities  
* **Dependencies:** `dartzen_core`, `dartzen_firestore`

### **`dartzen_storage`**

* **Purpose:** Google Cloud Storage utilities for DartZen.  
* **Scope:** File upload, download, and management helpers.

### **`dartzen_cache`**

* **Purpose:** Caching layer for DartZen.  
* **Scope:**  
  * In-memory caching for local development  
  * Google Cloud Memorystore for production  
  * Transparent API for other packages

### **`dartzen_telemetry`**

* **Purpose:** Event logging and analytics.  
* **Scope:**  
  * Server events  
  * Client analytics consumption and resend  
  * Integration with `dartzen_firestore` and Google Analytics

### **`dartzen_jobs`**

* **Purpose:** Background and scheduled jobs.  
* **Scope:**  
  * Task scheduling  
  * Retry and error handling  
  * Integration with Firestore and cache

### **`dartzen_ai`**

* **Purpose:** AI integration.  
* **Scope:** Gemini / Vertex AI utilities and helpers

### **`dartzen_server`**

* **Purpose:** Shelf-based server runtime.  
* **Scope:** Application lifecycle, routing, middleware, and explicit GCP-native integrations

### **`dartzen_payments`**

* **Purpose:** Payment processing utilities.  
* **Scope:** Stripe integration, transaction handling, subscription management

### **`dartzen_localization`**

* **Purpose:** Globalization utilities for DartZen.  
* **Scope:**  
  * Multilingual UI and server responses  
  * Locale-aware formatting  
  * Integrated with accessibility standards

### **`dartzen_msgpack`**

* **Purpose:** MessagePack serialization utilities for DartZen.  
* **Scope:**  
  * High-performance binary serialization  
  * Shared by server and client packages  
  * Complements JSON serialization where needed

---

## **Client Packages**

### **`dartzen_ui_navigation`**

* **Purpose:** Unified navigation layer for Flutter apps.  
* **Scope:** Adaptive routing, platform-specific optimizations, accessibility, analytics integration

### **`dartzen_ui_identity`**

* **Purpose:** Identity UI components for Flutter.  
* **Scope:** Login, registration, profile management widgets; accessibility and analytics integrated

---

## **Architectural Notes**

* Packages do not assume usage context unless explicitly stated.  
* Infrastructure packages never depend on domain packages.  
* Client packages never contain server or infrastructure logic.  
* Emulators are preferred for local development.  
* Explicit configuration beats implicit magic.

DartZen grows by addition, not mutation.
