import 'package:dartzen_core/dartzen_core.dart';
import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;

import '../zen_navigation_item.dart';

/// Platform-specific navigation badge builder for desktop platforms.
/// Shows all navigation items in a NavigationRail.
m.Widget navigationBadge(ZenNavigationItem item, bool selected) {
  if (item.badgeCount != null && item.badgeCount! > 0) {
    return (dzIsIOS || dzIsMacOS)
        ? m.Badge(
            label: c.Text('${item.badgeCount}'),
            child: c.Icon(item.icon),
          )
        : m.Badge(
            label: m.Text('${item.badgeCount}'),
            child: m.Icon(item.icon),
          );
  }
  return (dzIsIOS || dzIsMacOS) ? c.Icon(item.icon) : m.Icon(item.icon);
}
