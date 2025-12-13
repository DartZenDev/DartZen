import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/navigation_messages.dart';
import '../zen_navigation.dart';
import '../zen_navigation_item.dart';
import 'navigation_badge.dart';
import 'navigation_more.dart';

/// Platform-specific navigation builder for mobile platforms.
/// It define the current platform via env variable DZ_PLATFORM
/// and returns a CupertinoTabBar or BottomNavigationBar
const PlatformNavigationBuilder buildMobileNavigation = _widget;

Widget _widget({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onItemSelected,
  required List<ZenNavigationItem> items,
  required ZenLocalizationService localization,
  required String language,
  String? labelMore,
}) {
  final messages = NavigationMessages(localization, language);
  final moreLabel = labelMore ?? messages.more;
  final List<ZenNavigationItem> visible = items.take(dzMaxItemsMobile).toList();
  final List<ZenNavigationItem> overflow = items.length > dzMaxItemsMobile
      ? items.skip(dzMaxItemsMobile).toList()
      : <ZenNavigationItem>[];

  // Determine the index to show in the bottom navigation bar
  // If an overflow item is selected, show the "more" button as selected
  final displayIndex = selectedIndex >= dzMaxItemsMobile
      ? dzMaxItemsMobile // Show "more" as selected
      : selectedIndex;

  // Display the selected item's page (works for both regular and overflow items)
  final Widget bodyWidget = items[selectedIndex].builder(context);

  // Build bottom navigation bar items
  final Iterable<BottomNavigationBarItem> itemsElements = visible
      .take(dzMaxItemsMobile)
      .map((ZenNavigationItem e) => BottomNavigationBarItem(
            icon: navigationBadge(e, false),
            label: e.label,
          ));

  // Create the "more" item if there are overflow items
  final List<BottomNavigationBarItem> itemsMoreLabel = overflow.isNotEmpty
      ? <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(
                dzIsIOS ? CupertinoIcons.ellipsis : Icons.more_horiz,
              ),
              label: moreLabel),
        ]
      : <BottomNavigationBarItem>[];

  final itemsList = <BottomNavigationBarItem>[
    ...itemsElements,
    ...itemsMoreLabel
  ];

  // Handle navigation bar tap
  void handleNavTap(int index) {
    if (overflow.isNotEmpty && index == dzMaxItemsMobile) {
      // Tapped on "more" button - navigate to the overflow menu page
      Navigator.of(context).push(
        dzIsIOS
            ? CupertinoPageRoute<void>(
                builder: (BuildContext context) => NavigationMorePage(
                  overflowItems: overflow,
                  selectedIndex: selectedIndex,
                  indexOffset: dzMaxItemsMobile,
                  onItemSelected: (int globalIndex) {
                    onItemSelected(globalIndex);
                    Navigator.of(context).pop();
                  },
                  labelMore: moreLabel,
                ),
              )
            : MaterialPageRoute<void>(
                builder: (BuildContext context) => NavigationMorePage(
                  overflowItems: overflow,
                  selectedIndex: selectedIndex,
                  indexOffset: dzMaxItemsMobile,
                  onItemSelected: (int globalIndex) {
                    onItemSelected(globalIndex);
                    Navigator.of(context).pop();
                  },
                  labelMore: moreLabel,
                ),
              ),
      );
    } else {
      // Tapped on a regular item
      onItemSelected(index);
    }
  }

  return Scaffold(
    body: bodyWidget,
    bottomNavigationBar: dzIsIOS
        ? CupertinoTabBar(
            currentIndex: displayIndex,
            onTap: handleNavTap,
            items: itemsList,
            height: 64,
          )
        : BottomNavigationBar(
            currentIndex: displayIndex,
            onTap: handleNavTap,
            items: itemsList,
            type: BottomNavigationBarType.fixed,
          ),
  );
}
