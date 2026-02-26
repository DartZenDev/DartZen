# DartZen UI Admin

[![pub package](https://img.shields.io/pub/v/dartzen_ui_admin.svg)](https://pub.dev/packages/dartzen_ui_admin)
[![codecov](https://codecov.io/gh/DartZenDev/DartZen/graph/badge.svg?token=HD0SYZB0VB)](https://codecov.io/gh/DartZenDev/DartZen)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

A Flutter UI package for admin CRUD screens in the DartZen ecosystem.

> **Note:** This package is part of the [DartZen](https://github.com/DartZenDev/DartZen) monorepo.

## ⚙️ Overview

`dartzen_ui_admin` provides a set of screens, models, and utilities for
building admin panels that manage resources via the DartZen transport layer.
Everything follows strict **Zen Architecture** — no direct HTTP calls, no
raw JSON encoding, no `Uri` construction.

## 🛠️ Features

- **Resource Metadata** — Define resources with typed fields and permissions.
- **List Screen** — Paginated `DataTable` with edit/delete actions.
- **Form Screen** — Create and edit records with field validation.
- **Delete Dialog** — Confirmation dialog with transport-backed deletion.
- **Theme Extension** — Customizable colors, styles, and spacing.
- **Localization** — Full `ZenLocalizationService` integration.
- **State Provider** — Riverpod provider for dependency injection.

## 📦 Installation

### In a Melos Workspace

If you are working within the DartZen monorepo, add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_ui_admin:
    path: ../packages/dartzen_ui_admin
```

### External Usage

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dartzen_ui_admin: ^latest_version
```

## 🚀 Quick Start

```dart
import 'package:dartzen_ui_admin/dartzen_ui_admin.dart';

// 1. Define a resource.
final usersResource = ZenAdminResource<Map<String, dynamic>>(
  resourceName: 'users',
  displayName: 'Users',
  fields: const [
    ZenAdminField(name: 'id', label: 'ID', editable: false),
    ZenAdminField(name: 'name', label: 'Name', required: true),
    ZenAdminField(name: 'email', label: 'Email'),
  ],
  permissions: const ZenAdminPermissions(
    canRead: true,
    canWrite: true,
    canDelete: true,
  ),
);

// 2. Display the list screen.
ZenListScreen(
  resource: usersResource,
  client: myAdminClient,
  messages: myMessages,
  onEdit: (id) => navigateToForm(id),
  onDelete: (id) => showDeleteDialog(id),
  onCreate: () => navigateToForm(null),
);
```

## 🏗️ Architecture

```
lib/
  dartzen_ui_admin.dart          # Barrel file
  src/
    admin/
      zen_admin_permissions.dart # Read/write/delete flags
      zen_admin_field.dart       # Field metadata
      zen_admin_resource.dart    # Resource descriptor
      zen_admin_query.dart       # Pagination query
      zen_admin_page.dart        # Paginated result
      zen_admin_client.dart      # Transport-backed client
    state/
      admin_client_provider.dart # Riverpod provider
    l10n/
      admin.en.json              # English translations
      zen_admin_messages.dart    # Typed message accessor
    theme/
      admin_theme_extension.dart # ThemeExtension
    screens/
      zen_list_screen.dart       # Paginated list
      zen_form_screen.dart       # Create/edit form
      zen_delete_dialog.dart     # Delete confirmation
```

## 🧩 Models

### ZenAdminPermissions

Controls which actions are available in the UI:

```dart
const permissions = ZenAdminPermissions(
  canRead: true,
  canWrite: true,
  canDelete: false,
);
```

### ZenAdminField

Describes a single field on a resource:

```dart
const field = ZenAdminField(
  name: 'email',
  label: 'Email Address',
  visibleInList: true,
  editable: true,
  required: true,
);
```

### ZenAdminResource

Combines fields and permissions into a resource descriptor:

```dart
final resource = ZenAdminResource<Map<String, dynamic>>(
  resourceName: 'products',
  displayName: 'Products',
  fields: [nameField, priceField],
  permissions: fullPermissions,
);
```

## 🚚 Transport Client

`ZenAdminClient` communicates exclusively through `ZenTransport`:

| Operation | Descriptor ID  | Reliability |
| --------- | -------------- | ----------- |
| Query     | `admin.query`  | atMostOnce  |
| Fetch     | `admin.fetch`  | atMostOnce  |
| Create    | `admin.create` | atLeastOnce |
| Update    | `admin.update` | atLeastOnce |
| Delete    | `admin.delete` | atLeastOnce |

Route conventions are encoded in the payload `path` field (e.g.,
`/v1/admin/users/query`).

## 🎨 Theming

Register `AdminThemeExtension` in your `ThemeData`:

```dart
ThemeData(
  extensions: [
    AdminThemeExtension.fallback().copyWith(
      headerColor: Colors.indigo.shade100,
      actionColor: Colors.indigo,
    ),
  ],
);
```

## 🌐 Localization

Messages are loaded via `ZenLocalizationService`:

```dart
await service.loadModuleMessages(
  ZenAdminMessages.module,
  'en',
  modulePath: 'packages/dartzen_ui_admin/lib/src/l10n',
);
final messages = ZenAdminMessages(service, 'en');
```

## 🧪 Testing

Tests use `mocktail` for mocking `ZenTransport` and `ZenAdminClient`:

```shell
flutter test packages/dartzen_ui_admin
```

## 🔒 Authentication & Authorization

**This package contains no authentication logic.** This is by design —
authentication protection is distributed across layers with clear
ownership boundaries.

| Layer         | Responsibility                                              | Package                         |
| ------------- | ----------------------------------------------------------- | ------------------------------- |
| **Routing**   | Guard admin routes; redirect unauthenticated users to login | Host app (`go_router` redirect) |
| **Transport** | Attach auth tokens to outbound requests                     | `dartzen_transport`             |
| **Backend**   | Reject unauthorized requests on every endpoint              | `dartzen_server`                |
| **UI**        | Show/hide actions based on `ZenAdminPermissions`            | `dartzen_ui_admin`              |

`ZenAdminPermissions` controls **UI element visibility only** — it is not
a security boundary. The host application must resolve
identity → role → permissions before constructing `ZenAdminResource`.

### Required: Route Guard

Your host app **MUST** implement a route guard that redirects
unauthenticated users away from admin screens. Using `go_router`:

```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    // Read auth state from dartzen_ui_identity's session store.
    final session = ref.read(identitySessionStoreProvider);
    final isAuthenticated = session.asData?.value != null;
    if (!isAuthenticated) return '/login';
    return null;
  },
  builder: (context, state) => const AdminListScreen(),
),
```

Without this guard, admin screens are accessible to anyone.

See the [example app](example/) for a complete working demonstration
using `dartzen_ui_identity`'s `LoginScreen` and
`identitySessionStoreProvider`.

## 📄 License

Apache 2.0 — see [LICENSE](LICENSE).
