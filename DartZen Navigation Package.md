# **🧭 Epic: DartZen Navigation Package**

High-level epic for implementing the `dartzen_navigation` package — the unified, adaptive navigation layer for DartZen.  
This epic covers initialization, API design, adaptive behavior, overflow handling, theming, documentation, and testing.

---

## **\[DZ-Nav-1\] Package Scaffolding & Initial Setup**

### **Description**

Create the initial folder structure and minimal scaffolding for `dartzen_navigation` inside the monorepo. Add pubspec, analysis\_options, CI workflow, and placeholder files for future modules.

### **Acceptance Criteria**

* Package exists in `/packages/dartzen_navigation`  
* Contains minimal pubspec with proper dependencies  
* Has `/lib/src` folder with placeholders: `navigation_controller.dart`, `navigation_item.dart`, `navigation_theme.dart`  
* Lints enabled (DartZen unified lints)  
* CI pipeline validates formatting & static checks

### **Labels**

`package`, `navigation`, `infrastructure`

### **Estimation**

4h

---

## **\[DZ-Nav-2\] Define Navigation Item Model**

### **Description**

Create the unified `ZenNavigationItem` model with fields:

* `id`  
* `label`  
* `icon`  
* `route`  
* `badgeCount`  
* `isPrimary`  
* optional callbacks  
  No priority — ordering is determined by list order (DartZen Zen principle)

### **Acceptance Criteria**

* Model supports JSON-like map constructor  
* Model is immutable  
* Model integrates with Riverpod as external state

### **Labels**

`package`, `navigation`, `model`

### **Estimation**

3h

---

## **\[DZ-Nav-3\] Navigation Controller (Riverpod)**

### **Description**

Implement a Riverpod-based controller responsible for:

* consuming external state (user-defined list of navigation items)  
* emitting structured layout state for UI  
* handling index changes  
* exposing stream/state notifier for selected item

### **Acceptance Criteria**

* `NavigationController` works with `StateNotifier`  
* Supports selecting an item by index/id  
* Emits updates when external list changes  
* No UI dependencies

### **Labels**

`package`, `navigation`, `riverpod`, `state-management`

### **Estimation**

6h

---

## **\[DZ-Nav-4\] Smart Overflow Algorithm**

### **Description**

Implement algorithm:

* Wide screens → show horizontal navbar  
* Medium screens → show NavigationRail-style sidebar  
* Narrow screens → collapse into drawer  
  Also implement **overflow logic**: items that don't fit move into “More” section.

### **Acceptance Criteria**

* Adaptive breakpoints implemented (`xs`, `sm`, `md`, `lg`, `xl`)  
* Overflow works for both horizontal and vertical layouts  
* Unit tests cover various screen widths

### **Labels**

`package`, `navigation`, `ui-logic`, `adaptive`

### **Estimation**

10h

---

## **\[DZ-Nav-5\] Navigation Widgets**

### **Description**

Implement UI widgets:

* `ZenNavigationBar`  
* `ZenNavigationRail`  
* `ZenNavigationDrawer`  
* `ZenOverflowMenu`

Widgets must:

* consume state from NavigationController  
* follow Flutter best practices  
* provide meaningful defaults

### **Acceptance Criteria**

* Widgets fully functional in isolation  
* Internal layout matches Material 3 standards  
* Overflow menu works in web/mobile/desktop

### **Labels**

`package`, `navigation`, `flutter-ui`

### **Estimation**

12h

---

## **\[DZ-Nav-6\] Adaptive Highlight System**

### **Description**

Implement active item highlighting rules:

* Subtle highlight on desktop  
* Strong pill-style highlight on mobile  
* Hover support on web/desktop

### **Acceptance Criteria**

* Highlighting adapts automatically based on platform \+ screen width  
* Visual tests/screenshots included  
* No conditional branching in user code (fully automatic)

### **Labels**

`package`, `navigation`, `ui`, `theming`

### **Estimation**

6h

---

## **\[DZ-Nav-7\] Documentation & Example Pages**

### **Description**

Write documentation for:

* Setup  
* Providing Riverpod state  
* Adaptive navigation behavior  
* Overflow examples  
  Add example code in `/example`.

### **Acceptance Criteria**

* README complete  
* Full working example under `/example`  
* Screenshots included  
* Explains Zen principles: simplicity, external source of truth

### **Labels**

`docs`, `package`, `navigation`

### **Estimation**

5h

---

## **\[DZ-Nav-8\] Package Testing**

### **Description**

Create unit tests, widget tests, and golden tests.

### **Acceptance Criteria**

* Coverage \> 80%  
* Golden tests for highlights, rail, navbar, drawer  
* Smart overflow logic fully covered

### **Labels**

`testing`, `package`, `qa`

### **Estimation**

8h

---

---

# **📱 Epic: Minimal Flutter App Using dartzen\_navigation**

A minimal Flutter application demonstrating how to use the navigation package in a realistic environment.

---

## **\[DZ-App-1\] Create Minimal Flutter App**

### **Description**

Initialize a minimal Flutter app named `dartzen_navigation_demo`. Add required dependencies, folder structure, and config.

### **Acceptance Criteria**

* App compiles on Android, iOS, Web, Desktop  
* Contains `/lib/app.dart`, `navigation_items.dart`, `main.dart`  
* Uses Riverpod

### **Labels**

`app`, `flutter`, `setup`

### **Estimation**

2h

---

## **\[DZ-App-2\] Provide Navigation Items via Riverpod**

### **Description**

Define a provider that returns a list of navigation items. This list simulates dynamic navigation.

### **Acceptance Criteria**

* Provider returns at least 4 items  
* Items use icons, labels, routes  
* Reordering items changes UI automatically

### **Labels**

`app`, `riverpod`, `navigation`

### **Estimation**

2h

---

## **\[DZ-App-3\] Integrate ZenNavigation Widgets**

### **Description**

Connect app's layout to the navigation package:

* Use `ZenNavigationBar` for mobile  
* Use `ZenNavigationRail` for tablet  
* Use automatic adaptive mode for desktop \+ web

### **Acceptance Criteria**

* App UI switches when resizing screen  
* Overflow behaves correctly  
* Navigation updates selected screen

### **Labels**

`app`, `flutter-ui`, `navigation`

### **Estimation**

4h

---

## **\[DZ-App-4\] Example Screens**

### **Description**

Create dummy screens: Home, Search, Profile, Settings.

### **Acceptance Criteria**

* Each screen displays its name  
* Navigation works between screens  
* Screen persists selection on web refresh

### **Labels**

`app`, `flutter`

### **Estimation**

2h

---

## **\[DZ-App-5\] App Testing**

### **Description**

Test integration with `dartzen_navigation`.

### **Acceptance Criteria**

* Golden tests for app layout  
* Adaptive behavior tests  
* Integration test for navigation switching

### **Labels**

`testing`, `app`, `qa`

### **Estimation**

5h

# **🚀 Epic: Platform-Specific Build System for `dartzen_navigation`**

### **Description**

Implement a unified and configurable build strategy that adapts `dartzen_navigation` and DartZen apps to different platforms: **Flutter Mobile**, **Flutter Web**, **Flutter Desktop**, and **Dart CLI**.  
The system must:

* automatically include/exclude navigation features depending on platform  
* support conditional imports (`stub`, `mobile`, `web`)  
* expose one public API that behaves consistently on all platforms  
* ensure no platform-specific dependencies leak upward into consuming apps  
* enable CI rules that validate platform-specific compilation  
* support future extensions (e.g., wearOS, visionOS, Linux embedded)

All tasks inside this epic must result in fully automated platform-aware builds without manual switches.

---

# **Tasks**

## **\[NAV\] Define Platform Build Strategy**

### **Description**

Design the architecture for platform-dependent code inside `dartzen_navigation` using:

* conditional imports (`if (dart.library.html)`, `if (dart.library.io)`)  
* abstract interfaces \+ concrete platform implementations  
* fallback stubs for unsupported features

Document the rules for:

* how packages add new platform adapters  
* how build runners detect the correct adapter  
* how to avoid cyclic imports

### **Acceptance Criteria**

* Architecture diagram added to `/docs/navigation/platform_build.md`  
* Clear rules for adding new platform adapters  
* Unified public API described

**Estimate:** 3h  
**Labels:** architecture, platform, navigation

---

## **\[NAV\] Implement `INavigationAdapter` Interface**

### **Description**

Create a common interface that represents platform-specific behavior for navigation UI and lifecycle.

Adapters must be created:

* `navigation_adapter_mobile.dart`  
* `navigation_adapter_web.dart`  
* `navigation_adapter_desktop.dart`  
* `navigation_adapter_stub.dart` (fallback)

### **Acceptance Criteria**

* Interface declared in `lib/src/adapter/inavigation_adapter.dart`  
* Each platform has an implementation with matching method signatures  
* Stub logs warnings in debug mode

**Estimate:** 4h  
**Labels:** platform, flutter, navigation

---

## **\[NAV\] Add Conditional Imports for All Public Navigation Widgets**

### **Description**

Refactor all public widgets into thin wrappers that conditionally import platform adapters.

Example (simplified pattern):

`import 'navigation_adapter_stub.dart'`  
    `if (dart.library.html) 'navigation_adapter_web.dart'`  
    `if (dart.library.io) 'navigation_adapter_mobile.dart';`

Widgets must not import platform code directly.

### **Acceptance Criteria**

* All widgets compile correctly on all platforms  
* No platform-specific code leaks outside `adapter/*`  
* Analyzer warnings eliminated

**Estimate:** 6h  
**Labels:** refactor, platform, flutter

---

## **\[NAV\] Implement Web-Optimized Navigation (TopBar \+ Drawer)**

### **Description**

This implements the feature you explicitly required:

* wide Web → top navigation bar  
* medium Web → hybrid / collapsible navigation  
* narrow Web → Drawer only

Uses:

* LayoutBuilder  
* MediaQuery breakpoints  
* adaptive theme hooks

### **Acceptance Criteria**

* Demo confirms responsive behavior in browser  
* Breakpoints defined and documented  
* No dependency on screen size in mobile runtimes

**Estimate:** 8h  
**Labels:** flutter, web, navigation, responsive

---

## **\[NAV\] Implement Mobile/Tablet NavigationRail \+ Drawer Variant**

### **Description**

Add adaptive layout rules for iOS/Android/tablets:

* tablets → NavigationRail  
* phones → BottomNavigationBar  
* phones in landscape → Rail  
* overflow → “smart overflow” menu

### **Acceptance Criteria**

* Matches Material 3 guidelines  
* Uses the shared `INavigationAdapter`  
* Behaviour identical on Android/iOS

**Estimate:** 8h  
**Labels:** flutter, mobile, navigation

---

## **\[NAV\] Desktop Variant (Expanded Sidebar)**

### **Description**

Add a desktop-optimized NavigationRail/Sidebar variant:

* always expanded  
* supports pinned menu  
* keyboard shortcuts (Ctrl+1, Ctrl+2…)

### **Acceptance Criteria**

* Works on Windows, macOS, Linux  
* No UI overlap with window chrome  
* Implement keyboard accelerators

**Estimate:** 6h  
**Labels:** desktop, flutter, navigation

---

## **\[CI\] Multi-Platform Build Pipeline**

### **Description**

Add GitHub Actions workflow that builds:

* Flutter Web  
* Flutter iOS (simulator)  
* Flutter Android  
* Flutter macOS  
* Flutter Windows  
* Flutter Linux  
* Dart CLI (dry run only)

Must use `melos bootstrap` \+ `melos run build:all`.

### **Acceptance Criteria**

* CI fails if any platform fails to compile  
* Cache is configured to minimize build time  
* Badge added to README

**Estimate:** 5h  
**Labels:** ci, platform, devops

---

## **\[TEST\] Platform-Specific Snapshot Tests**

### **Description**

Add snapshot tests for Web/Mobile/Desktop adapters with:

* goldens where possible  
* behavior testers (hover, tap, resize)  
* stub adapter tests

### **Acceptance Criteria**

* Snapshot tests pass for all platforms supported by Flutter test framework  
* Golden files committed  
* Adapter behavior verified

**Estimate:** 4h  
**Labels:** tests, flutter, navigation

---

## **\[EPIC COMPLETE\] Final Integration & QA**

### **Description**

Perform full QA of all platform variants:

* Web responsive behavior  
* Mobile NavigationRail / BottomNav logic  
* Desktop Sidebar logic  
* Overflow menu  
* Conditional adapters  
* Public API behavior

### **Acceptance Criteria**

* QA checklist completed  
* No debug logs in production builds  
* Example app compiles across all platforms

**Estimate:** 3h  
**Labels:** qa, verification

