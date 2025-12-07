import 'package:flutter/material.dart';

import '../zen_navigation.dart';
import '../zen_navigation_item.dart';
import 'navigation_badge.dart';

/// Platform-specific navigation builder for desktop platforms.
/// Shows all navigation items in a NavigationRail.
const PlatformNavigationBuilder buildDesktopNavigation = _widget;

Widget _widget({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onItemSelected,
  required List<ZenNavigationItem> items,
  String? labelMore,
}) =>
    Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onItemSelected,
          labelType: NavigationRailLabelType.all,
          destinations: [
            ...items.map(
              (e) => NavigationRailDestination(
                icon: navigationBadge(e, false),
                label: Text(e.label),
              ),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: items[selectedIndex].builder(context)),
      ],
    );
