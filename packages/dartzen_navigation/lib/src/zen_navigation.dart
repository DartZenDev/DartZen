// Conditional imports for platform-specific widgets
import 'package:dartzen_core/dartzen_core.dart';
import 'package:flutter/widgets.dart';

import './widgets/navigation_stub.dart'
    if (dart.library.html) './widgets/navigation_web.dart'
    if (dart.library.io) './widgets/navigation_native.dart';
import 'zen_navigation_item.dart';

/// A navigation widget [ZenNavigation] that can be used to navigate between
/// different screens.
///
/// It is a builder pattern that allows you to create a navigation widget
/// with a builder function that returns a widget. It is platform adaptive
/// and will render different layouts based on the platform. On mobile it
/// applies 'overflow' behavior, meaning that if there are more than 4 items,
/// a 'more' button will be displayed, which will open a screen with the
/// remaining items. The 'more' label is customizable.
///
/// Example:
/// ```dart
/// final navigation = ZenNavigation(
///   items: [
///     ZenNavigationItem(
///       id: 'home',
///       label: 'Home', // or t.Home for l10n
///       icon: const Icon(Icons.home),
///       builder: (context) => const HomeScreen(),
///     ),
///   ],
///   selectedIndex: 0,
///   onItemSelected: (id) { // Handle navigation if needed },
///   labelMore: 'More', // or t.More for l10n
/// );
/// ```
class ZenNavigation extends StatelessWidget {
  /// Creates a new [ZenNavigation].
  const ZenNavigation({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    super.key,
    this.labelMore = 'More',
  });

  /// The selected index of the navigation item.
  final int selectedIndex;

  /// The callback function that is called when a navigation item is selected.
  final ValueChanged<int> onItemSelected;

  /// The list of navigation items.
  final List<ZenNavigationItem> items;

  /// The label for the "more" button.
  final String? labelMore;

  @override
  Widget build(BuildContext context) {
    // Expect DZ_PLATFORM to be set
    assert(dzPlatform.isNotEmpty);
    // Forward to platform-specific implementation
    return buildPlatformNavigation(
      context: context,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      items: items,
      labelMore: labelMore,
    );
  }
}

/// typedef for platform factory
typedef PlatformNavigationBuilder = Widget Function({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onItemSelected,
  required List<ZenNavigationItem> items,
  String? labelMore,
});
