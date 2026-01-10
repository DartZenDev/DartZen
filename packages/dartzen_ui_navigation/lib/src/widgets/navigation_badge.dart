import 'package:dartzen_core/dartzen_core.dart';
import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;

import '../zen_navigation_item.dart';

/// Platform-specific navigation badge builder for desktop platforms.
/// Shows all navigation items in a NavigationRail.
m.Widget navigationBadge(ZenNavigationItem item, bool selected) {
  final icon = (dzIsIOS || dzIsMacOS) ? c.Icon(item.icon) : m.Icon(item.icon);

  final m.Widget child;
  if (item.badgeCount != null && item.badgeCount! > 0) {
    child = (dzIsIOS || dzIsMacOS)
        ? m.Badge(
            label: c.Text('${item.badgeCount}'),
            child: icon,
          )
        : m.Badge(
            label: m.Text('${item.badgeCount}'),
            child: icon,
          );
  } else {
    child = icon;
  }

  return m.Semantics(
    label: item.label,
    button: true,
    selected: selected,
    child: child,
  );
}
