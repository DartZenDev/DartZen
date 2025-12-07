import 'package:dartzen_navigation/dartzen_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';

/// Provider for navigation items
final navigationItemsProvider = Provider<List<ZenNavigationItem>>((ref) {
  return [
    ZenNavigationItem(
      id: 'home',
      label: 'Home',
      icon: Icons.home,
      builder: (context) => const HomeScreen(),
    ),
    ZenNavigationItem(
      id: 'search',
      label: 'Search',
      icon: Icons.search,
      builder: (context) => const SearchScreen(),
    ),
    ZenNavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person,
      builder: (context) => const ProfileScreen(),
      badgeCount: 3,
    ),
    ZenNavigationItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings,
      builder: (context) => const SettingsScreen(),
    ),
  ];
});

/// Notifier for selected navigation index
class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setIndex(int index) {
    state = index;
  }
}

/// Provider for selected navigation index
final selectedNavigationIndexProvider =
    NotifierProvider<NavigationIndexNotifier, int>(NavigationIndexNotifier.new);
